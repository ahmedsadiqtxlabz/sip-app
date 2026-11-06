# Sip App - Comprehensive Implementation Plan

## 1. Executive Summary & Project Context

* **App Name:** Sip (Daily Water-Intake Tracker)
* **Platforms:** iOS & Android (Single Flutter Codebase)
* **Target Delivery:** QA Handover by midday tomorrow (Fast-paced, iterative execution)
* **Core Value Proposition:** Intuitive, frictionless water logging with single-tap quick adds, animated water-fill ring, daily streaks, gentle reminders, and rich visual feedback.
* **Monetization Model:**
  * **Free Tier:** Banner ad (320x50) on Home and History screens.
  * **Sip Pro:** $2.99/month or $19.99/year (with 7-day free trial on yearly). Unlocks ad removal, smart reminders, custom themes, expanded drink types, weekly insights, Apple Health sync, and widgets.

---

## 2. Technical Stack & Architecture

### Core Tech Stack
* **Framework:** Flutter (v3.24+ / Dart 3.5+)
* **State Management:** `flutter_bloc` (v8.1+) with reactive, predictable state streams
* **Architecture:** Clean Architecture (Feature-First: Presentation, Domain, Data)
* **Dependency Injection:** `get_it` + `injectable` (or manual service locator for speed)
* **Local Storage:** `hive` + `hive_flutter` (high-performance NoSQL key-value database, no SQLite boilerplate)
* **In-App Purchases:** `purchases_flutter` (RevenueCat SDK)
* **Monetization (Ads):** `google_mobile_ads` (AdMob 320x50 Banner)
* **Notifications & Alarms:** `flutter_local_notifications` + `timezone` (exact alarms on Android 13+)
* **Permissions & Tracking:** `permission_handler` + `app_tracking_transparency` (iOS ATT flow)
* **Styling & Assets:** `flutter_svg`, `google_fonts` (or bundled local fonts), custom canvas animations for water ring

---

## 3. Clean Architecture Folder Structure

```
lib/
├── app.dart                        # MaterialApp, global BlocProviders, theme bindings
├── main.dart                       # Entry point, dependency injection init, Hive init
├── core/
│   ├── constants/                  # App constants, storage keys, product IDs, ad unit IDs
│   ├── error/                      # Failures and Exception classes
│   ├── network/                    # Network info (if needed for IAP/Ads sync)
│   ├── services/
│   │   ├── ad_service.dart         # Google Mobile Ads wrapper (test vs real IDs)
│   │   ├── analytics_service.dart  # Event tracking (optional/stubbed)
│   │   ├── notification_service.dart # Local notifications, scheduled exact reminders
│   │   ├── purchase_service.dart   # RevenueCat wrapper & entitlement listener
│   │   └── storage_service.dart    # Hive box initializer and persistent settings
│   ├── theme/
│   │   ├── app_colors.dart         # Extracted palette: Primary, Water Cyan/Blue, Surface, Dark/Light
│   │   ├── app_typography.dart     # Font scales, weights, line heights
│   │   └── app_theme.dart          # ThemeData for Light and Dark modes
│   ├── utils/                      # Date formatters, unit converters (ml <-> oz), hydration math
│   └── widgets/                    # Reusable atom/molecule widgets
│       ├── ad_banner_widget.dart   # 320x50 Banner Ad wrapper with Pro-tier hiding
│       ├── custom_button.dart      # Rounded primary/secondary buttons
│       ├── custom_card.dart        # Elevated/flat container cards
│       ├── custom_sheet.dart       # Draggable bottom sheet scaffold
│       └── water_fill_ring.dart    # Custom animated circular progress indicator
└── features/
    ├── onboarding/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/           # Welcome, Goal Calculator, Notification permission request
    ├── water_tracking/
    │   ├── data/
    │   │   ├── datasources/        # WaterTrackingLocalDataSource (Hive box)
    │   │   ├── models/             # DrinkEntryModel, DailyIntakeModel
    │   │   └── repositories/       # WaterTrackingRepositoryImpl
    │   ├── domain/
    │   │   ├── entities/           # DrinkEntry, DailyIntake, StreakInfo
    │   │   ├── repositories/       # WaterTrackingRepository interface
    │   │   └── usecases/           # LogDrink, RemoveDrink, GetTodayIntake, CalculateStreak
    │   └── presentation/
    │       ├── bloc/               # WaterTrackingBloc (Events, States)
    │       ├── pages/              # HomeScreen
    │       └── widgets/            # QuickAddSheet, DrinkLogTile, DailyStreakBadge
    ├── history/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/           # HistoryScreen (Daily/Weekly/Monthly calendar & charts)
    ├── reminders/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/           # ReminderSettingsScreen, IntervalPicker, SoundSelector
    ├── profile/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/           # ProfileScreen, DailyGoalEditor, UnitSelector, Themes
    └── subscription/
        ├── data/
        ├── domain/
        └── presentation/           # PaywallScreen, PlanSelectionCard, FeatureComparisonList
```

---

## 4. Phase-by-Phase Execution Roadmap

### Phase 1: Project Scaffolding & Setup (Immediate)
* Initialize Flutter project: `flutter create --org com.txlabz --project-name sip .`
* Configure `pubspec.yaml` with required dependencies:
  * `flutter_bloc`, `equatable`, `get_it`
  * `hive`, `hive_flutter`, `path_provider`
  * `purchases_flutter`, `google_mobile_ads`
  * `flutter_local_notifications`, `timezone`, `permission_handler`, `app_tracking_transparency`
  * `flutter_svg`, `intl`
* Configure Android:
  * Minimum SDK 21+, Target SDK 34+
  * Notification & Exact Alarm permissions in `AndroidManifest.xml`
  * Google AdMob App ID metadata in `AndroidManifest.xml`
* Configure iOS:
  * Deployment target iOS 13.0+
  * `Info.plist`: NSUserTrackingUsageDescription (ATT), GADApplicationIdentifier (AdMob)
  * Podfile setup with static frameworks

### Phase 2: Design Tokens, Style Guide & Common Components
* Extract color palette, typography, spacing, border radiuses, and icons from design spec.
* Build `AppColors`, `AppTypography`, `AppTheme` (Light/Dark support).
* Develop Custom Animated `WaterFillRing` widget with smooth fluid rise animation.
* Build shared UI atoms: `SipButton`, `SipCard`, `SipSheetHeader`, `DrinkTypeChip`.

### Phase 3: Core Water Tracking Loop & Local Storage (Day 1 Focus)
* Set up Hive models: `DrinkEntry` (id, amount, unit, timestamp, drinkType), `UserSettings` (goal, unit, theme, isPro).
* Implement `WaterTrackingRepository` & `WaterTrackingBloc`:
  * Load daily total, goal progress percentage, streak count.
  * Quick-add logs (+250ml, +500ml, +750ml, custom amount).
  * Undo / delete drink log.
* Build `HomeScreen`:
  * Header with current date, streak counter, and settings/profile avatar.
  * Central animated `WaterFillRing` with current intake vs goal.
  * Quick-Add buttons row.
  * Today's drink activity list with timestamps.
  * Bottom sheet for custom drink logging (volume, drink type: water, coffee, tea, etc.).

### Phase 4: Onboarding & Goal Customization
* 3-step intuitive onboarding:
  1. Value proposition & animated hero.
  2. Smart Goal Calculator (weight, activity level, climate -> recommended daily intake).
  3. Notification permission & scheduled reminders setup.
* Persistent flag `hasSeenOnboarding` in Hive.

### Phase 5: Reminders & Notification Scheduling (Android 13+ & iOS)
* Notification service with customizable intervals (e.g., every 1h, 1.5h, 2h).
* Quiet hours (e.g., no reminders between 10 PM and 7 AM).
* Android exact alarm permission and foreground notification channels.
* Interactive notification action (e.g., "Log 250ml" directly from notification).

### Phase 6: History & Insights
* Daily / Weekly / Monthly aggregate breakdown.
* Bar charts showing intake consistency across the week.
* Streak tracking and hydration completion percentage.

### Phase 7: Monetization (Paywall, RevenueCat, AdMob & iOS ATT)
* **AdMob Integration:**
  * Banner ad widget (320x50) anchored at the bottom of Home and History screens.
  * Conditional rendering: automatically hides when user has active Pro entitlement.
  * iOS ATT pre-permission dialog before requesting tracking authorization.
* **Paywall & RevenueCat:**
  * `PaywallScreen` matching Claude design spec.
  * Monthly ($2.99) vs Yearly ($19.99 with 7-day trial) toggle.
  * "Restore Purchases" button and terms / privacy policy links.
  * Entitlement listener updating `isPro` state in BLoC and Hive instantly.

### Phase 8: Profile, Settings & QA Verification
* Switch unit between milliliters (ml) and fluid ounces (fl oz).
* Custom goal adjustments and theme picker.
* Export data (CSV) - Pro gated feature.
* End-to-end smoke test on iOS Simulator and Android Emulator.
* Release builds for TestFlight and Google Play Internal Testing.

---

## 5. Required Manager Action Items (For Ahmed Sadiq & Sajid Nawaz)

To ensure store setup proceeds in parallel with coding:
1. **App Identifiers:**
   * **Bundle ID (iOS):** `com.txlabz.sip`
   * **Package Name (Android):** `com.txlabz.sip`
2. **In-App Purchase Product IDs (RevenueCat / Stores):**
   * Monthly Subscription: `sip_pro_monthly` ($2.99 / month)
   * Yearly Subscription: `sip_pro_yearly` ($19.99 / year with 7-day free trial)
   * Entitlement Identifier in RevenueCat: `pro`
3. **AdMob Units:**
   * iOS App ID: `ca-app-pub-9873700043748462~8980091689`
   * iOS Banner: `ca-app-pub-9873700043748462/3525594186`
   * Android App ID: `ca-app-pub-9873700043748462~3014670325`
   * Android Banner: `ca-app-pub-9873700043748462/6666140726`
   *(Development will use standard Google Test IDs `ca-app-pub-3940256099942544/6300978111` to prevent account flags before verification completes).*

