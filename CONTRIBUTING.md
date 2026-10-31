# Contributing to OzDoro

OzDoro is a lightweight macOS menu bar Pomodoro timer built with SwiftUI and AppKit. Bug reports, fixes, tests, and translations are welcome. Please discuss larger behavior changes in an issue first and keep pull requests focused.

## Development setup

- macOS 13+ and Xcode 15+ for the app.
- Swift 5.9+ for core tests, which also run on Linux.
- Python 3 for localization checks.
- `swift-format`: included with Xcode 16+, or install with `brew install swift-format`. The Makefile finds it on PATH or through `xcrun`.

```sh
git clone https://github.com/ozhantr/ozdoro.git
cd ozdoro
make verify
make build
make run
```

Quit an existing OzDoro instance before launching another build. No signing credentials are needed for development.

## Checks

```sh
make format        # format Swift files
make verify        # strict formatting/lint, localization checks, and tests
make build-debug   # universal macOS Debug build
make build         # universal macOS Release build
```

Tests live in `Tests/OzDoroCoreTests` and run through Swift Package Manager with `make test`. The app's Xcode scheme has no test target. For timer changes, use deterministic dates in engine tests. CI runs these checks and builds both Debug and Release for Apple Silicon and Intel.

Changes involving the popover, audio, accessibility, or sleep/wake notifications also need manual testing. See the [release checklist](Docs/RELEASING.md#manual-checks).

## Code organization

See [Architecture](Docs/ARCHITECTURE.md) for responsibilities and timer behavior. Keep domain logic in `Core`, macOS integration in `Services` and `App`, and interface code in `UI`. Avoid new dependencies or abstractions without a concrete need.

## Translations

1. Add or update a language in `OzDoro/Resources/Localizable.xcstrings`.
2. Translate every entry, including tooltips and accessibility labels. Preserve format placeholders such as `%@` and `%lld`.
3. Keep labels short enough to fit the popover and test using Xcode's **Edit Scheme → Run → Options → App Language**.
4. Run `make check-localizations`.

Installed sound names must remain unchanged; only the silent option's label is translated.

## App icon

The source artwork is `Docs/Chosen-App-Icon-Source.png`. Update the size variants and `Contents.json` in `OzDoro/Resources/Assets.xcassets/AppIcon.appiconset` together. Check readability at small sizes and include a preview with icon changes.

## Pull requests and issues

- Explain the change and link any related issue.
- Add tests for behavior changes and run the checks above.
- Include screenshots for visible changes and update translations when changing text.
- Exclude build output, local settings, credentials, and private logs.

Bug reports should include macOS and OzDoro versions, reproduction steps, expected and actual behavior, and relevant error messages. Keep feedback respectful and constructive.

## Branches and commits

Create a branch from `main`: `feat/feature-name`, `fix/bug-description`,
`docs/documentation-update`, `refactor/component-name`, `test/test-description`,
or `ci/workflow-improvement`.

All commits, including the initial commit, follow
[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
`type(scope): description`. Omit the scope when none is meaningful.

| Type | Purpose |
| --- | --- |
| feat | New functionality |
| fix | Bug fixes |
| refactor | Internal changes without behavior changes |
| perf | Performance improvements |
| test | Tests |
| docs | Documentation |
| style | Formatting only |
| build | Build system, dependencies and Xcode configuration |
| ci | GitHub Actions and CI/CD |
| chore | Repository maintenance |

Use English, lowercase types and scopes, and an imperative description starting
with a lowercase letter. Do not end the subject with a period. Aim for at most
72 characters. Each commit must represent one logical change; avoid empty commits
and vague subjects such as "update files". Add a body when context is needed.
For breaking changes, use both `!` and a `BREAKING CHANGE:` footer explaining impact
and migration.

Examples:

```text
feat(timer): add configurable long break duration
fix(popover): prevent unexpected closing during countdown
test(timer): add pause and resume regression tests
docs(contributing): document commit conventions
ci(actions): update GitHub Actions
chore(repo): initialize OzDoro open-source project
```

## Review expectations

Keep pull requests focused, describe what changed and why, follow existing style,
and avoid unrelated changes. Use Conventional Commits for commits and PR titles
(the title becomes the squash commit). Add or update tests where appropriate and
ensure CI passes before merging. Report any checks you could not run.

Use the bug report or feature request template. Feature requests should describe
the user problem, a proposed solution and alternatives. Discuss substantial UI,
behavior or architecture changes before implementing them. Keep code simple,
native, performant and compatible with macOS 13+. Do not introduce dependencies
without explaining their need. Never include secrets or disable macOS protections.
