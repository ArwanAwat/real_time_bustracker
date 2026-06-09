# 🚌 BusTrack Pro — Real-Time Bus Tracker

A feature-rich, Android-focused Flutter application for real-time bus fleet tracking using SQLite as the local database. Built with clean architecture, `Provider` state management, and a live auto-refresh simulation engine.

---

## 📱 Screenshots

| Dashboard | Fleet List | Bus Detail | Trip Log |
|-----------|------------|------------|----------|
| Fleet stats & active buses | Searchable & filterable list | Live GPS + occupancy | Per-bus position history |

---

## ✨ Features

- **Live Auto-Refresh** — Fleet data simulates GPS updates every 5 seconds, toggleable at runtime
- **Dashboard** — Fleet-wide stats: total buses, on-route count, delayed count, average speed, average occupancy
- **Fleet List** — Full bus list with search (by number, route, driver) and status filters
- **Bus Detail Screen** — Real-time coordinates, speed, occupancy bar, driver info, last-updated timestamp
- **Trip Log** — Per-bus SQLite-backed position history with peak speed and peak passenger stats
- **Add / Edit Bus** — Full form to add new buses or edit existing ones in-place
- **Delete Bus** — Remove a bus from the fleet with confirmation dialog
- **Animated LIVE Badge** — Pulsing indicator showing whether a bus has reported recently
- **Occupancy Bar** — Color-coded (green → orange → red) passenger load indicator
- **Status Change Alerts** — Snackbar notifications when a bus changes status during simulation
- **4 Statuses** — `On Route`, `Delayed`, `Stopped`, `Maintenance`

---

## 🗂️ Project Structure

```
bus_tracker/
├── pubspec.yaml
├── analysis_options.yaml
└── lib/
    ├── main.dart
    ├── models/
    │   ├── bus.dart               # Bus data model with occupancy helpers
    │   └── bus_log.dart           # GPS log entry model
    ├── database/
    │   └── database_helper.dart   # SQLite setup, CRUD, seeding, simulation
    ├── providers/
    │   └── bus_provider.dart      # ChangeNotifier state + auto-refresh timer
    ├── screens/
    │   ├── home_screen.dart       # Tab shell: Dashboard + Fleet tabs
    │   ├── dashboard_screen.dart  # Stats grid + active bus preview
    │   ├── bus_detail_screen.dart # Full bus info + manual GPS trigger
    │   ├── add_edit_bus_screen.dart # Add / edit form
    │   └── trip_log_screen.dart   # Timeline of historical GPS logs
    └── widgets/
        ├── bus_card.dart          # Rich list card with occupancy + actions
        ├── stat_card.dart         # Dashboard metric card
        └── live_badge.dart        # Animated pulsing LIVE / OFFLINE badge
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3) |
| Platform | Android (primary target) |
| Local Database | SQLite via `sqflite ^2.3.0` |
| State Management | `provider ^6.1.2` (`ChangeNotifier`) |
| Date Formatting | `intl ^0.19.0` |
| Path Resolution | `path ^1.9.0` |

---

## 🗄️ Database Schema

### `buses` table

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-increment primary key |
| `busNumber` | TEXT | Unique bus identifier (e.g. `B-101`) |
| `routeName` | TEXT | Human-readable route description |
| `driverName` | TEXT | Assigned driver name |
| `latitude` | REAL | Current GPS latitude |
| `longitude` | REAL | Current GPS longitude |
| `status` | TEXT | `on_route` / `delayed` / `stopped` / `maintenance` |
| `speed` | INTEGER | Current speed in km/h |
| `passengerCount` | INTEGER | Current number of passengers |
| `capacity` | INTEGER | Maximum seat capacity |
| `lastUpdated` | TEXT | ISO 8601 timestamp of last GPS ping |
| `createdAt` | TEXT | ISO 8601 timestamp of record creation |

### `bus_logs` table

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-increment primary key |
| `busId` | INTEGER FK | References `buses(id)`, cascades on delete |
| `latitude` | REAL | Logged GPS latitude |
| `longitude` | REAL | Logged GPS longitude |
| `speed` | INTEGER | Speed at time of log |
| `status` | TEXT | Status at time of log |
| `passengerCount` | INTEGER | Passenger count at time of log |
| `recordedAt` | TEXT | ISO 8601 timestamp |

> Logs are automatically pruned to the latest **100 entries per bus** to keep the database lean.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Android Studio or VS Code with Flutter/Dart plugins
- Android device or emulator (API 21+)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/ArwanAwat/real_time_bustracker
cd bus_tracker

# 2. Install dependencies
flutter pub get

# 3. Run on Android
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The output APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔧 Configuration

### `pubspec.yaml` dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.9.0
  intl: ^0.19.0
  provider: ^6.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

### Disable Gradle daemon (fixes Windows file-lock issues)

In `android/gradle.properties`:

```properties
org.gradle.daemon=false
```

---

## 🧩 Architecture

```
UI Layer (Screens + Widgets)
        │
        ▼
BusProvider (ChangeNotifier)
        │  ├── exposes bus list, stats, filter, search
        │  ├── auto-refresh Timer (every 5s)
        │  └── calls DatabaseHelper
        │
        ▼
DatabaseHelper (Singleton)
        │  ├── getAllBuses()
        │  ├── insertBus() / updateBus() / deleteBus()
        │  ├── getFleetStats() / getFleetAverages()
        │  ├── insertLog() / getLogsForBus()
        │  └── simulateGpsUpdate() / simulateAllBuses()
        │
        ▼
SQLite (sqflite)
   ├── buses table
   └── bus_logs table
```

---

## 🐛 Common Issues & Fixes

### Build fails on Windows — `Unable to delete directory after 10 attempts`

Stale Gradle daemon locking build cache files. Fix:

```bash
flutter clean
rd /s /q build
.\gradlew.bat --stop
flutter pub get
flutter run
```

### `Scaffold.of()` crash — `does not contain a Scaffold`

Make sure `HomeScreen`'s state class uses `SingleTickerProviderStateMixin` and the `TabController` is initialized in `initState` with `vsync: this`, not `vsync: Scaffold.of(context)`.

### App installs but shows blank screen

Run `flutter clean && flutter pub get` then hot restart (not hot reload) after schema changes.

---

## 📋 Roadmap

- [ ] Google Maps integration for live map view
- [ ] Real GPS via device location services
- [ ] Push notifications for status changes
- [ ] WebSocket / REST API backend integration
- [ ] Export trip logs to CSV
- [ ] Dark mode support
- [ ] Multi-language support (Arabic, Kurdish)

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgements

- [sqflite](https://pub.dev/packages/sqflite) — SQLite plugin for Flutter
- [provider](https://pub.dev/packages/provider) — Lightweight state management
- [Flutter](https://flutter.dev) — Cross-platform UI toolkit by Google