# SJ TRACKING SOLUTION — Invoice Manager

A Flutter invoice manager app with three switchable invoice templates
(Classic, Modern, Minimal), a company profile with logo upload, payment
receipts, monthly totals, TZS currency formatting, and a GPS Service
Charge subscription flow with automatic expiry tracking.

## What's included

```
sj_tracking_solution/
├── pubspec.yaml
└── lib/
    ├── main.dart                        # App entry point, theme, providers
    ├── models/
    │   ├── invoice.dart                  # Invoice, InvoiceTemplate/Status,
    │   │                                  #   ServiceType (GPS), totals, expiry
    │   ├── invoice_item.dart             # Line item model
    │   ├── client.dart                   # Bill-to client model
    │   ├── company_profile.dart          # Company name/contact + logo (base64)
    │   └── receipt.dart                  # Payment receipt model
    ├── providers/
    │   ├── invoice_provider.dart         # State + persistence + monthly stats
    │   ├── company_profile_provider.dart # State + persistence for the profile
    │   └── receipt_provider.dart         # State + persistence for receipts
    ├── screens/
    │   ├── home_screen.dart              # Dashboard, monthly overview, invoice list
    │   ├── invoice_form_screen.dart      # Create/edit invoice, GPS months picker
    │   ├── invoice_preview_screen.dart   # Template switcher, Mark-as-Paid, PDF
    │   ├── company_profile_screen.dart   # Edit company info + upload logo
    │   ├── receipts_screen.dart          # List of all issued receipts
    │   └── receipt_preview_screen.dart   # Receipt PDF preview/print/share
    └── utils/
        ├── pdf_generator.dart            # 3 invoice templates + receipt PDF,
        │                                  #   logo embedding, GPS info box
        ├── formatters.dart               # TZS currency & date formatting
        └── month_utils.dart              # Month arithmetic (GPS expiry, stats)
```

## Features

- **Dashboard**: total invoices, revenue collected, outstanding balance, plus
  a **Monthly Overview** card (pick any of the last 12 months) showing
  **Total Invoiced**, **Amount Paid**, and **Remaining** for that month.
- **Company Profile**: set your business name/address/contact info and
  **upload a logo** (camera or gallery). The logo is embedded on every
  invoice and receipt PDF, and a snapshot is stored on each invoice so
  historical documents keep the logo that was active when they were made.
- **Create/Edit invoices**: client info, dynamic line items, tax %,
  discount %, notes, due dates, status (Draft/Unpaid/Paid/Overdue).
- **3 invoice templates**, switchable per invoice with live PDF preview:
  Classic (formal/bordered), Modern (color header band), Minimal (clean,
  whitespace-heavy).
- **GPS Service Charge**: choose "GPS Service Charge" as the invoice's
  service type, pick the **number of months paid** (1/2/3/6/12), and the
  app automatically computes and displays the **expiry date**
  (issue date + months paid) — on the form, the invoice list, the PDF, and
  the receipt. Expired coverage is flagged in red.
- **Receipts**: tap **"Mark Paid"** on an invoice preview, choose a payment
  method, and a receipt is generated automatically (receipt number, amount,
  date, method — plus GPS coverage details if applicable). All receipts are
  listed under the receipt icon in the app bar and can be printed/shared as
  PDF.
- **Currency**: all amounts are shown in **Tanzanian Shillings**, e.g.
  `TZS 150,000`.
- **Local persistence**: invoices, receipts, and the company profile are
  saved on-device (`shared_preferences`) as JSON — no backend required.

## Setup (run this on your machine — Flutter SDK required)

This sandbox doesn't have the Flutter SDK or access to pub.dev, so the
platform folders (`android/`, `ios/`, `web/`, etc.) are not generated here.
To get a runnable project:

```bash
# 1. Unzip this project, then from inside the folder:
flutter create . --project-name sj_tracking_solution --org com.sjtracking

# If it asks about overwriting existing files (pubspec.yaml, lib/main.dart),
# choose "n" / skip — the ones already in this project are the ones you want.

# 2. Install dependencies
flutter pub get

# 3. Run it
flutter run
```

### Camera/gallery permissions for the logo upload
`image_picker` needs platform permission entries, added after `flutter create .`:
- **Android** (`android/app/src/main/AndroidManifest.xml`): add
  `<uses-permission android:name="android.permission.CAMERA"/>` if you want
  camera capture (gallery picking alone needs no extra permission on modern
  Android).
- **iOS** (`ios/Runner/Info.plist`): add `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription` with a short reason string, e.g.
  "Used to upload your company logo."

### Set the app display name / icon (optional)
- **Android**: edit `android/app/src/main/AndroidManifest.xml` →
  `android:label="SJ TRACKING SOLUTION"`.
- **iOS**: edit `ios/Runner/Info.plist` → `CFBundleName` /
  `CFBundleDisplayName` → `SJ TRACKING SOLUTION`.
- To customize the app icon, use the `flutter_launcher_icons` package.

### Currency
Currency is set to TZS in `lib/utils/formatters.dart`. Change
`currencySymbol` there if you need a different currency.

## Notes
- All data is stored locally on the device only (no cloud sync / login).
  If you need multi-device sync or a backend, that would be a separate
  addition (e.g. Firebase or a REST API).
- The three invoice PDF templates and the receipt PDF all share the same
  underlying invoice/receipt data — switching templates never loses info.
- GPS Service Charge expiry = issue date + months paid (calendar months,
  day-of-month clamped for shorter target months, e.g. 31 Jan + 1 month →
  28/29 Feb).

# Invoice
# SJtracking-invoice
# SJtracking-invoice
# SJtracking-invoice
# invoice
# invoice
# invoice
# Invoice-generator
# invoice
