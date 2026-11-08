# CP Expiry Tracker

A Flutter application for tracking product expiry dates.

The project is set up for **web** (the primary target for now, since no
Android environment is available) and **Android**.

## Requirements

- Flutter SDK 3.24 or newer (Dart 3.5+)

## Getting started

```sh
flutter pub get
flutter run -d chrome        # run in a browser
flutter run -d web-server    # serve without launching a browser
```

## Development

```sh
flutter analyze              # static analysis / lints
flutter test                 # unit and widget tests
flutter build web            # production build into build/web
```

## Project layout

- `lib/` – application source (`lib/main.dart` is the entry point)
- `test/` – widget and unit tests
- `web/` – web host page and PWA manifest
- `android/` – Android host project
