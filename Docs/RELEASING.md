# Releasing OzDoro

## Distribution status

OzDoro is currently distributed as source. Signed/notarized downloads and a Homebrew Cask are not available. Local builds require no paid Apple Developer membership.

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

Do not create a Homebrew Cask. Future binary distribution needs a separately
reviewed signing and notarization plan; never bypass macOS security protections.
