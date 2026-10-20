# Contributing to Pickpick

Thanks for helping improve Pickpick. Bug reports, focused fixes, documentation improvements, and well-scoped features are welcome.

Please keep discussions constructive and follow these guidelines. An issue or pull request that lacks the information needed to review it might be closed until it can be completed.

## Before you start

- Search [existing issues](https://github.com/focale-editor/pickpick/issues) before opening a new one.
- Use the relevant issue template and include a minimal reproduction for bugs.
- For a substantial feature or breaking change, open an issue and wait for maintainer feedback before investing in an implementation.
- If you plan to fix an existing issue, leave a comment so work is not duplicated.

Security-sensitive reports should not include secrets, private files, or personal data in a public issue.

## Development setup

Pickpick follows the SDK constraint in [`pubspec.yaml`](pubspec.yaml). Install a compatible stable Flutter SDK, fork the repository, and run:

```sh
git clone https://github.com/YOUR_ACCOUNT/pickpick.git
cd pickpick
flutter pub get
```

Create a focused branch from `main`:

```sh
git switch main
git pull --ff-only
git switch -c fix/short-description
```

## Making changes

- Keep each pull request focused on one fix or feature.
- Match the existing architecture, naming, and formatting conventions.
- Add or update tests for behavior changes and bug fixes.
- Update public API documentation, examples, and the README when behavior changes.
- Preserve compatibility unless the accepted issue explicitly calls for a breaking change.
- Do not bump the package version or edit the changelog unless a maintainer asks you to.

For breaking changes, document the migration path and use deprecation before removal when practical.

Document public behavior and add tests for changed platform contracts. Keep screenshot capture out of this single-color API.

## Quality checks

Before opening a pull request, run:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze
flutter test
flutter test --platform chrome test/web_test.dart
```

Add any narrower platform, corpus, or integration checks relevant to the files you changed. If a check cannot run in your environment, explain why in the pull request.

## Platform validation

Linux portal tests use an isolated in-process D-Bus server. Browser tests replace
EyeDropper with a fake and exercise the JavaScript boundary. Neither replaces a
manual selection/cancellation test on the real system interface.

Run the example on each affected platform. For macOS packaging changes, validate
both CocoaPods and Swift Package Manager on a Mac. Mention any platform checks
that could not run.

On Windows, check selection and cancellation on monitors with different scales,
including a monitor left of the primary display. Escape, right-click and Alt-Tab
must release the picker; selection must not activate the underlying application's
buttons. Repeat selection after cancellation and after changing the monitor
layout. Validate the MSVC build on Windows even when cross-compilation passes.

## Pull requests

Open the pull request against `main` and:

- explain the problem and the chosen solution;
- link the related issue with `Fixes #123` when applicable;
- describe the tests you ran and the platforms you exercised;
- call out compatibility, performance, licensing, or migration implications;
- keep review follow-up commits on the same branch.

Pull request titles must use a [Conventional Commits](https://www.conventionalcommits.org/) type:

- `fix:` for bug fixes;
- `feat:` for new features;
- `docs:` for documentation;
- `test:` for tests;
- `refactor:` for behavior-preserving restructuring;
- `perf:` for performance work;
- `build:`, `ci:`, or `chore:` for maintenance;
- `revert:` for reverts.

Add `!` for an accepted breaking change, for example `feat!: replace the legacy decoder API`.

A maintainer may ask for changes before merging. Continue pushing to the pull request branch; the pull request updates automatically.

