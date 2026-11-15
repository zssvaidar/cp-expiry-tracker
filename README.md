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

## Ephemeral EC2 smoke test

`scripts/ec2-ephemeral.sh` launches a throwaway EC2 instance, keeps it for
4 minutes, then terminates it. It is meant for testing the deployer.

```sh
AWS_REGION=us-east-1 scripts/ec2-ephemeral.sh
```

It needs AWS CLI v2 and credentials. Defaults: `t3.micro`, latest Amazon
Linux 2023, default VPC. You can override them with `INSTANCE_TYPE`,
`AMI_ID`, `SUBNET_ID`, `SECURITY_GROUP_ID` and `LIFETIME_SECONDS`.
The script terminates the instance itself, including on Ctrl-C or error.
As a backup, the instance also shuts itself down after the lifetime with
shutdown behaviour `terminate`, so it is removed even if the script dies.
