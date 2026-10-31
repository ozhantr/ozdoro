# Project instructions

## Code
- Follow Swift, SwiftUI, AppKit and native macOS Human Interface Guidelines.
- Write readable, maintainable, lightweight code; apply SOLID where useful.
- Prefer simple solutions. Preserve the architecture; justify structural changes.
- Avoid unnecessary abstractions and third-party dependencies; review dependencies before adding them.
- Never change UI or functionality unless explicitly requested.
- Preserve macOS 13+ support, OzDoro branding and bundle ID `io.github.ozhantr.ozdoro`.

## Validation
- Run relevant tests after code changes; add practical regression tests for fixes.
- Run `make format-check` and `make check-localizations`; keep English, German and Turkish consistent.
- Run `make test`; use `make build-debug` and `make build` for appropriate universal Debug/Release validation.
- Report exact checks and limitations. Never claim unexecuted tests or builds passed.

## Git and security
- Always follow Conventional Commits 1.0.0 and the rules in CONTRIBUTING.md.
- Use English imperative descriptions starting lowercase, lowercase types/scopes, descriptive scopes and no final period; aim for 72 characters.
- Keep commits small and logical; review changes before staging.
- Never commit generated artifacts, secrets, credentials, signing certificates, private keys or tokens.
- Always request explicit approval before pushing changes or publishing releases.
- Never force-push without explicit approval.
- Never disable Gatekeeper, SIP or other macOS security protections.
- Keep Actions permissions minimal and release workflows secure.
- Distribution is source-only. Do not attempt Developer ID signing or notarization.
