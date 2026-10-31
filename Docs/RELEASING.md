# Releasing OzDoro

## Distribution status

The v0.1.0 release remains source-only. Starting with v0.1.2, explicitly unsigned/unnotarized universal developer builds are available through a personal Homebrew tap. Signed/notarized downloads are not available. Local builds require no paid Apple Developer membership.

Developer ID signing and notarization require Apple credentials that the project does not currently have. Unsigned downloads may be blocked by Gatekeeper; ad hoc signing does not provide publisher trust. See [Apple Developer ID](https://developer.apple.com/developer-id/) and [notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Before a release

- Run `make verify` and `make build`, and confirm GitHub CI passes.
- Complete the manual checks below on supported macOS versions and architectures.
- Confirm version metadata and retain bundle ID `io.github.ozhantr.ozdoro`.
- Review the release notes and included assets/licenses.

## Manual checks

- Verify the menu bar item, popover, and absence of a Dock icon or main window.
- Leave the popover and settings pickers open across timer ticks; check mouse and keyboard controls.
- Test pause/resume, restart, reset, and skipping breaks.
- Complete four focus rounds: three short breaks, then a long break; breaks start automatically and focus waits for Start.
- Sleep across focus and break deadlines; verify the wake behavior described in [Architecture](ARCHITECTURE.md) and a single completion sound.
- Test alert sounds, silence, saved settings, and long-break changes. A started break retains its duration until restarted.
- Check English, German, and Turkish layouts and VoiceOver labels.

## Source-only v0.1.0 release

Release publication and tag pushes require explicit maintainer approval.
The manual `release.yml` workflow only runs readiness checks: it has read-only
permissions, no signing secrets, no artifact uploads and no release creation.
`Scripts/package_release.sh` intentionally fails without touching credentials or
keychains. Developer ID signing and notarization are not part of this process.

1. Run `make verify`, `make build-debug` and `make build`; verify both executable
   architectures with `lipo <executable> -verify_arch arm64 x86_64`. Confirm remote CI passes.
2. Complete the manual checklist above and record any untested platforms.
3. Confirm version `0.1.0`, MIT licensing and icon artwork redistribution rights.
4. Prepare release notes describing features, source build instructions and known
   limitations. Do not attach unsigned application binaries or promise signed downloads.
5. Request approval for the exact commit, `v0.1.0` tag and source-only release notes.
6. Only after approval, create and push an annotated tag and publish the reviewed
   release using GitHub's automatically generated source archives.

## Unsigned developer builds and personal Homebrew tap

The separate `unsigned-release.yml` workflow is manual-only and accepts an existing
annotated version tag whose commit belongs to main. It rejects v0.1.0 and the canceled v0.1.1 binary release. The existing
readiness workflow and disabled signing script remain unchanged; there is currently
no operational signed/notarized release workflow to run.

1. Bump both Xcode configurations and add `Docs/Releases/VERSION.md`. Record manual
   runtime gaps rather than implying build success proves runtime compatibility.
2. Run formatting, localization, unit tests and universal Debug/Release builds.
3. Run `python3 Scripts/package_unsigned.py --app build/Build/Products/Release/OzDoro.app --version VERSION`.
   Repeat into another output directory and compare ZIP bytes. Validate the checksum.
4. Merge through a PR with required CI. Create a new annotated tag; never replace
   existing tags. Dispatch the unsigned workflow from main after publication approval.
5. The build job has read-only permissions. Only the publish job has contents write.
   It verifies checksums and creates a new release without replacing assets. No Apple
   credentials, signing, notarization, or security overrides are used.
6. Download the published ZIP and checksum and compare them before updating the tap.
   Use its actual URL and SHA-256 in `ozhantr/homebrew-tap/Casks/ozdoro.rb`.
7. Run `brew style`, `brew audit --cask --strict --online`, download/checksum checks,
   install, uninstall and reinstall. Preserve quarantine. Separately record Gatekeeper
   assessment; an installed app is not necessarily permitted to launch.

The ZIP includes the MIT license inside the app so it survives Cask installation.
The ZIP has sorted entries, fixed timestamps, normalized permissions and uncompressed
contents. Repackaging identical bundle bytes is reproducible. Different Xcode versions
or independent compilations are not promised to yield byte-identical binaries.

Install: `brew install --cask ozhantr/tap/ozdoro`. Update with `brew update` then
`brew upgrade --cask ozhantr/tap/ozdoro`; uninstall with `brew uninstall --cask ozhantr/tap/ozdoro`.

A personal tap does not imply official Homebrew acceptance or Apple trust. Official
inclusion requires a current supported distribution passing Gatekeeper checks,
working update detection, demonstrated public interest and maintainer review.
Unsigned/unnotarized developer builds do not satisfy the official signing baseline.
Never disable Gatekeeper/SIP, remove quarantine, or document bypasses.

References: [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook),
[Tap maintenance](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap),
[Acceptable Casks](https://docs.brew.sh/Acceptable-Casks),
[Tap Trust](https://docs.brew.sh/Tap-Trust).
