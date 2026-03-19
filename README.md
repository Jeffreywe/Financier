# Financier

Financier is an Android-first Flutter personal finance app focused on practical, manual money management.

## What It Does

- Track accounts, transactions, and debts.
- Support recurring transactions with forecasting.
- Organize spending with budget categories and a 50/30/20-style budget view.
- Provide dashboard visibility for month totals and near-term cash flow.
- Import/export core data with XLSX.

## Core Features

### Dashboard
- Monthly summary: income, expenses, net, and left-to-budget.
- Account and debt rollups.
- Month navigation controls (`Previous` / `Next`) for month-scoped summary + calendar.
- Calendar view with transaction indicators and day drill-down.
- Future Outlook:
	- Biweekly periods: `Previous`, `Current`, `Next 1..6`.
	- Monthly periods: previous/current/next.
	- Per-occurrence paid/unpaid toggles for scheduled items.

### Transactions
- CRUD for transaction records.
- Types: `income`, `expense`, `note`.
- Recurrence frequencies: `none`, `weekly`, `biweekly`, `monthly`, `quarterly`, `annually`.
- Category assignment and account linkage.

### Accounts
- CRUD for account records.
- Supported account types include checking, savings, credit, cash, and other.

### Budget
- Category-based budget tracking with bucket grouping (Needs/Wants/Savings).

### Debt
- CRUD for debts with debt type, balance, optional interest/minimum payment/due day, and notes.

### Data Port (Import/Export)
- XLSX export of accounts, transactions, debts, and categories.
- XLSX import with replace/merge behavior.
- Export folder persistence and export history.

## Architecture

- **State management**: `provider` + `ChangeNotifier`
- **Navigation**: `go_router` with `StatefulShellRoute.indexedStack`
- **Persistence**: local-first via `SharedPreferences` JSON storage
- **Structure**:
	- `lib/domain/models` for domain entities
	- `lib/data/repositories` and `lib/data/services` for data + persistence
	- `lib/ui/feature/*` for feature screens and view models
	- `lib/di/app_providers.dart` for dependency wiring
	- `lib/routing/app_router.dart` for app routes

## Main Tabs

- Dashboard
- Accounts
- Transactions
- Budget
- Debt

## Running the App

### Prerequisites
- Flutter SDK (matching `pubspec.yaml` constraints)
- Android SDK/device or emulator

### Commands
```bash
flutter pub get
flutter run --debug
```

## Quality Status

Audit status (March 2026):
- Architecture and routing/DI are aligned and stable.
- Recurring projection, paid-state handling, and data port flows are implemented.
- Automated test coverage is currently minimal (`test/widget_test.dart` placeholder).

Recommended routine checks:
```bash
dart format .
flutter analyze
flutter test
```

## Notes for Contributors (Human or AI)

- Keep business logic out of widgets.
- Keep persistence and I/O inside repositories/services.
- Prefer focused, minimal changes over broad refactors unless requested.
- Update this README and `.github/copilot-instructions.md` when behavior or architecture changes.
