# Sip — Minimalist Water Tracker & Habit App

A beautifully crafted, fluid hydration tracking application built with Flutter, focused on real-time fluid animations, custom drink presets, smart reminders, and dynamic themes.

---

## Table of Contents
1. [Tech Stack & Architecture](#tech-stack--architecture)
2. [Prerequisites](#prerequisites)
3. [Local Development Setup](#local-development-setup)
4. [Deployment Guide](#deployment-guide)
   - [Android (APK & App Bundle)](#1-android-deployment-google-play)
   - [iOS (TestFlight & App Store)](#2-ios-deployment-testflight--app-store)
5. [In-App Purchases & RevenueCat](#in-app-purchases--revenuecat)

---

## Tech Stack & Architecture

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: BLoC (`flutter_bloc`) with dependency injection via `get_it`
- **Local Storage**: Hive (`hive_flutter`) for offline persistence of drink logs and user settings
- **In-App Purchases**: RevenueCat (`purchases_flutter`) with StoreKit 2
- **Notifications**: `flutter_local_notifications` + `timezone` for localized dynamic reminder scheduling
- **Monetization**: Google Mobile Ads (`google_mobile_ads`) for non-Pro banner ads

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.0 or higher recommended)
- **iOS**: macOS, Xcode 15 or higher, CocoaPods (`sudo gem install cocoapods`)
- **Android**: Android Studio with Android SDK Platform 34+, Java 17

---

## Local Development Setup

Clone the repository and run the initial setup:

```bash
# 1. Clone the repository
git clone https://github.com/txlabz/sip-app.git
cd sip-app

# 2. Clear stale caches
flutter clean

# 3. Install Flutter packages
flutter pub get

# 4. Install iOS CocoaPods dependencies (macOS only)
cd ios
pod install
cd ..

# 5. Run on connected device or simulator
flutter run
```

---

## Deployment Guide

### 1. Android Deployment (Google Play)

#### Step 1: Clean and Prepare
Always run a fresh clean before creating release builds:

```bash
flutter clean
flutter pub get
```

#### Step 2: Build Release Binaries

- **To generate a standalone Release APK (for QA / direct testing):**
  ```bash
  flutter build apk --release
  ```
  *Output file location:*  
  `build/app/outputs/flutter-apk/app-release.apk`

- **To generate Split-ABI APKs (smaller file sizes for specific chipsets):**
  ```bash
  flutter build apk --split-per-abi --release
  ```

- **To generate an Android App Bundle (.aab) for Google Play Console:**
  ```bash
  flutter build appbundle --release
  ```
  *Output file location:*  
  `build/app/outputs/bundle/release/app-release.aab`

#### Step 3: Upload to Google Play Console
1. Open the [Google Play Console](https://play.google.com/console).
2. Select **Sip** &rarr; navigate to **Testing** &rarr; **Internal testing** (or **Production**).
3. Click **Create new release**.
4. Drag and drop the `app-release.aab` file from `build/app/outputs/bundle/release/`.
5. Enter your release notes and click **Save & Review Release**.

---

### 2. iOS Deployment (TestFlight & App Store)

#### Step 1: Clean and Install Pods
From the project root:

```bash
# 1. Clean Flutter build caches
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Clean and reinstall CocoaPods
cd ios
pod install
cd ..
```

#### Step 2: Open Workspace in Xcode
Always open the `.xcworkspace` file (never `.xcodeproj`):

```bash
open ios/Runner.xcworkspace
```

#### Step 3: Verify Signing & Configuration in Xcode
1. In the left project navigator, select the root **Runner** project.
2. Select the **Runner** target &rarr; go to the **Signing & Capabilities** tab.
3. Ensure:
   - **Automatically manage signing**: Checked ✅
   - **Team**: `TXLABZ LLC`
   - **Bundle Identifier**: `com.txlabz.sip`

#### Step 4: Archive the Build
1. In the top device selector bar in Xcode, select:  
   👉 **`Any iOS Device (arm64)`** *(do not choose a simulator or a specific physical device name)*.
2. From the top macOS menu, click **Product** &rarr; **Archive**.
3. Xcode will compile the project and open the **Organizer** window once finished.

#### Step 5: Distribute to App Store Connect / TestFlight
1. In the **Organizer** window, select your latest archive.
2. Click the blue **Distribute App** button on the right.
3. Select **TestFlight & App Store** &rarr; click **Distribute** (or **Next**).
4. Keep the default distribution options checked &rarr; click **Next**.
5. Select **Automatically manage signing** &rarr; click **Next**.
6. Review the summary and click **Upload**.

#### Step 6: Enable TestFlight Distribution
1. Log into [App Store Connect](https://appstoreconnect.apple.com/) &rarr; **Apps** &rarr; **Sip**.
2. Click the **TestFlight** tab &rarr; wait for the build status to change from *Processing* to **Ready to Test** (typically 5–10 mins).
3. If prompted for *Missing Export Compliance*, click **Manage** &rarr; select **No** &rarr; **Save**.
4. In your testing group (e.g. `QA Team`), ensure the build is attached and add your tester emails (`[EMAIL_ADDRESS]`).

---

## In-App Purchases & RevenueCat

- **Product IDs**:
  - `sip_pro_yearly` &mdash; Annual subscription with 7-day trial
  - `sip_pro_monthly` &mdash; Monthly subscription
- **Entitlement ID**: `pro`
- **Offering ID**: `default`
- **StoreKit Key**: App Store In-App Purchase Key (`.p8`) configured in RevenueCat dashboard.

---

## Versioning Policy

When preparing a new build, update `version` in [`pubspec.yaml`](file:///Users/affansaleem/Documents/GitHub/sip-app/pubspec.yaml#L19):

```yaml
version: 1.0.0+1
```

- **`1.0.0`** &mdash; Marketing version shown on the App Store (`CFBundleShortVersionString`).
- **`+1`** &mdash; Build number / binary count (`CFBundleVersion`). **Must be incremented for every subsequent upload to TestFlight or App Store Connect** (e.g. `1.0.0+2`, `1.0.0+3`).
