# DocScan

A document scanner for Android and iOS, built with Flutter. Scan paper with the
camera, clean it up, organize it, and export a PDF. Documents stay on the device.

Read `PLAN.md` first. It is the build plan and the rules of the road. This file is
the quickstart.

## What is here

- `lib/services/` wraps every plugin behind an interface: scanner, storage, OCR,
  PDF, export, and billing. The UI never touches a plugin directly.
- `lib/state/` holds the Riverpod controllers the screens watch.
- `lib/features/` holds the screens: library, scan flow, viewer, paywall, settings.
- `docs/` has the Play Store launch sequence and the freemium model.

## Before you build

The plugin versions in `pubspec.yaml` were current when the plan was written.
Confirm each on pub.dev and update before you run anything. This is the
documentation-first rule and it matters most for the scanner plugin, whose API
has changed between releases.

```bash
flutter pub get
flutter run        # on a real Android device, not an emulator, for the camera
```

The ML Kit scanner needs a device with at least 1.7 GB RAM. Below that it returns
an UNSUPPORTED error, which the scanner service already turns into a clean message.

## Build order

Follow the milestones in `PLAN.md`, M0 through M8. The short version:

1. Get the empty app running (M0).
2. Wire the scanner, save and view a document (M1).
3. Folders and search (M2).
4. PDF export and share (M3).
5. OCR and text search (M4).
6. RevenueCat paywall (M5).
7. Polish, then the 14-day closed test, then production (M6 to M8).

## The one thing that decides your launch date

Start the Play Store identity verification and the 12-tester closed test as early
as you can. The 14-day testing gate is fixed and cannot be rushed. See
`docs/play-store-launch.md`.
