# Play Store listing for Emikings DocScan

Everything below is ready to paste into the Play Console. Character limits
are noted where Play enforces them. Keep the copy honest; the review team
compares claims against app behavior.

## App details

- App name (30 characters max): `Emikings DocScan`
- Category: Productivity
- Free app with in-app purchases (once billing goes live)
- Contact email: iziedking17@gmail.com

## Short description (80 characters max)

```
Scan paper to PDF. Private by design: your documents never leave your phone.
```

## Full description (4000 characters max)

```
Emikings DocScan turns paper into clean, shareable PDFs and keeps every
scan on your phone.

Point the camera at a document and the scanner finds the edges, fixes the
perspective, and cleans up shadows for you. Save the result with a name,
sort it into folders, and find it again by searching. When you need to
send it, export a PDF and share it to any app, or print it directly.

PRIVATE BY DESIGN
Most scanner apps upload your documents to their servers. This one does
not. There is no account, no cloud, and no tracking. Scans, page images,
and recognized text live only on your device, and they leave it only when
you share or export them yourself. The app does not even request the
camera permission; scanning runs through your phone's own system scanner.

WHAT YOU GET FREE
- Scan multi-page documents with automatic edge detection
- A library with folders, rename, and search
- PDF export and sharing, with a small watermark
- Printing through your phone's print service

WHAT PRO ADDS
- Unlimited pages per document
- Text recognition on your scans, so search finds words inside them
- Clean exports with no watermark
- PDF tools: merge, reorder, and compress

Emikings DocScan is built for the everyday paperwork of real life:
receipts, contracts, IDs, school notes, and the letter you need to send
back today. Scan it, name it, find it later.

An EMIKINGS product.
```

## Data safety form

Play asks these questions in the Data safety section. Answer for the build
you are shipping.

While billing is off (closed testing with empty RevenueCat keys):

- Does your app collect or share any of the required user data types? **No**
- Is all of the user data collected by your app encrypted in transit?
  Not applicable, nothing is collected.
- Do you provide a way for users to request that their data is deleted?
  Not applicable. Documents are local; deleting them or uninstalling
  removes everything.

Once RevenueCat billing is live (before the production release with
purchases enabled), update the form:

- Purchase history: collected, shared with a service provider
  (RevenueCat processes purchases), not used for tracking.
- Device or other IDs: collected (an anonymous app user id RevenueCat
  generates), not used for tracking.
- Documents, images, and OCR text stay on the device and are never
  collected. Say so in the optional free-text field.

## Content rating questionnaire

Utility app. No user-generated public content, no violence, no gambling,
no social features, no unrestricted web access. Expect an Everyone rating.

## Privacy policy URL

Live and ready to paste into the console:

```
https://iziedking.github.io/docscan-privacy/
```

Published from the github.com/Iziedking/docscan-privacy repo via GitHub
Pages. The page text matches the in-app policy in
`lib/features/settings/privacy_policy_screen.dart`; if one changes, change
both.

## First release notes (closed testing)

```
First test release. Scan documents, organize them into folders, search by
name, and export or print PDFs. Everything stays on your device.
```

## Assets the console will ask for

- App icon: 512 x 512 PNG. Export from assets/icon/icon.png (already 1024,
  scale down).
- Feature graphic: 1024 x 500 PNG. Emblem on the brand black works; can be
  generated on request.
- Phone screenshots: at least 2, PNG or JPG, 16:9 or 9:16. Take them on
  the Pixel with a few real documents in the library: home, viewer,
  onboarding privacy page, paywall.
