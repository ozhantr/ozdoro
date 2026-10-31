#!/usr/bin/env python3
"""Validate and deterministically archive an existing unsigned OzDoro bundle.

Identical bundle bytes produce identical ZIP bytes. This does not promise that
independent Xcode builds or different toolchains produce identical executables.
No signing, notarization, quarantine changes or security overrides are performed.
"""
import argparse
import hashlib
import plistlib
import re
import stat
import subprocess
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--app', type=Path, required=True)
parser.add_argument('--version', required=True)
parser.add_argument('--output-dir', type=Path, default=Path('dist'))
args = parser.parse_args()
if not re.fullmatch(r'0|[1-9][0-9]*', args.version.split('.')[0]) or not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', args.version):
    parser.error('version must be MAJOR.MINOR.PATCH')
app = args.app.resolve()
if app.name != 'OzDoro.app' or not app.is_dir():
    parser.error('expected an existing OzDoro.app bundle')
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
for key, expected in {
    'CFBundleIdentifier': 'io.github.ozhantr.ozdoro',
    'CFBundleShortVersionString': args.version,
    'CFBundleExecutable': 'OzDoro',
    'LSMinimumSystemVersion': '13.0',
    'LSUIElement': True,
}.items():
    if info.get(key) != expected:
        parser.error(f'{key}: expected {expected!r}, got {info.get(key)!r}')
executable = app / 'Contents/MacOS/OzDoro'
subprocess.run(['lipo', str(executable), '-verify_arch', 'arm64', 'x86_64'], check=True)
if not executable.stat().st_mode & stat.S_IXUSR:
    parser.error('application executable lacks execute permission')
for resource in ['AppIcon.icns', 'Assets.car', *[f'{lang}.lproj/Localizable.strings' for lang in ('en', 'de', 'tr')]]:
    if not (app / 'Contents/Resources' / resource).is_file():
        parser.error(f'missing resource: {resource}')
paths = sorted(app.rglob('*'))
if any(p.is_symlink() or not (p.is_file() or p.is_dir()) for p in paths):
    parser.error('unexpected symlink or special file in application bundle')
license_bytes = (Path(__file__).resolve().parents[1] / 'LICENSE').read_bytes()
if b'MIT License' not in license_bytes:
    parser.error('missing MIT license notice')
args.output_dir.mkdir(parents=True, exist_ok=True)
archive = args.output_dir / f'OzDoro-{args.version}-macOS-universal-unsigned.zip'
# Stored entries avoid compressor-version differences; normalize timestamps and modes.
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_STORED) as output:
    for path in paths:
        if not path.is_file():
            continue
        entry = zipfile.ZipInfo(str(path.relative_to(app.parent)), (1980, 1, 1, 0, 0, 0))
        entry.create_system = 3
        mode = 0o755 if path.stat().st_mode & 0o111 else 0o644
        entry.external_attr = (stat.S_IFREG | mode) << 16
        output.writestr(entry, path.read_bytes())
    license_entry = zipfile.ZipInfo('OzDoro.app/Contents/Resources/LICENSE', (1980, 1, 1, 0, 0, 0))
    license_entry.create_system = 3
    license_entry.external_attr = (stat.S_IFREG | 0o644) << 16
    output.writestr(license_entry, license_bytes)
with zipfile.ZipFile(archive) as check:
    if check.read('OzDoro.app/Contents/Resources/LICENSE') != license_bytes:
        raise SystemExit('packaged MIT notice mismatch')
    if check.testzip() is not None:
        raise SystemExit('ZIP integrity check failed')
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(archive.suffix + '.sha256').write_text(f'{digest}  {archive.name}\n')
print(f'{digest}  {archive}')
print('Unsigned/unnotarized developer build; no Apple publisher trust is claimed.')
