---
applyTo: "**"
description: "Authoritative coding instructions for the Financier Flutter project."
name: "Financier Copilot Instructions"
---

# Financier Copilot Instructions

Use this file as the primary implementation guide for AI agents in this repository.

## Product Scope
- Financier is an Android-first personal finance app for one primary user.
- Prioritize practical daily workflows: manual entry, recurring tracking, debt visibility, and budgeting.
- Keep UX simple and deterministic; avoid speculative complexity.

## Current Feature Set (Source of Truth)
The app currently includes:
- Dashboard with monthly income/expense/net, account/debt totals, and left-to-budget.
- Dashboard calendar tied to selected month with day-level drill-down.
- Future Outlook card:
  - Biweekly mode with `Previous`, `Current`, and `Next 1..6` periods.
  - Monthly mode with previous/current/next periods.
  - Paid/unpaid occurrence toggling for scheduled items.
- Accounts CRUD.
- Transactions CRUD with types: income, expense, note.
- Recurrence options: none, weekly, biweekly, monthly, quarterly, annually.
- Budget screen with 50/30/20 style category bucketing.
- Debt CRUD with debt types and payment metadata.
- Import/Export (XLSX) with merge/replace import behavior and export history.

## Architecture Rules
- Keep strict layering: `ui -> domain -> data`.
- UI layer:
  - Widgets/screens in `lib/ui/feature/**`.
  - ViewModels use `ChangeNotifier`.
- Domain layer:
  - Models in `lib/domain/models/**`.
- Data layer:
  - Repositories in `lib/data/repositories/**`.
  - Services in `lib/data/services/**`.
- Business/data logic must not be placed in widgets.
- UI must not call storage/services directly.

## Project Structure (Current)
- `lib/main.dart`
- `lib/di/app_providers.dart`
- `lib/routing/app_router.dart`
- `lib/domain/models/`
- `lib/data/repositories/`
- `lib/data/services/`
- `lib/ui/core/`
- `lib/ui/feature/accounts/`
- `lib/ui/feature/budget/`
- `lib/ui/feature/dashboard/`
- `lib/ui/feature/data_port/`
- `lib/ui/feature/debt/`
- `lib/ui/feature/transactions/`

## State Management and DI
- Use `provider` + `ChangeNotifier`.
- Register dependencies in `lib/di/app_providers.dart`.
- For mutable UI state, use `ChangeNotifierProvider`.
- Do not use `ProxyProvider` for `ChangeNotifier` classes.

## Routing
- Use `go_router` with shell-based tab navigation.
- Primary tabs/routes are:
  - `/dashboard`
  - `/accounts`
  - `/transactions`
  - `/budget`
  - `/debt`
- Nested routes exist for add/edit forms and data port.

## Repository and Service Guidance
- Repositories are the app’s data boundary and source of truth for features.
- Services wrap technical concerns (local storage, file import/export).
- Preserve existing persistence behavior unless task explicitly changes it.

## Error Handling Guidance
- Current app uses user-facing string error states in ViewModels.
- When touching error flows, improve clarity and consistency without large refactors.
- Introduce typed exceptions only when requested or when scoped to changed feature.

## Data and Security
- Keep financial data handling privacy-aware.
- Do not introduce secrets or hardcoded credentials.
- Persist data via existing local storage patterns unless migration is requested.

## Quality Gates (After Edits)
Run these when applicable:
- `dart format .`
- `flutter analyze`
- `flutter test` (or targeted tests)

Minimum expectations:
- No new analyzer errors in changed files.
- No dead code or debug prints.
- Null-safety and naming consistency preserved.

## Testing Expectations
- Add targeted tests when changing business logic (especially recurring and budgeting behavior).
- Do not add broad test frameworks beyond current project scope.
- If tests are skipped by user request, report that clearly.

## Implementation Constraints
- Keep changes minimal and focused on the request.
- Rebuild legacy snippets into current architecture; do not paste blindly.
- Respect existing UI primitives/theme; avoid visual redesign unless requested.
- If a requirement is ambiguous, choose the simplest behavior consistent with existing flows.

## Audit Notes (March 2026)
- Strengths: architecture boundaries, DI/routing integrity, recurring and outlook logic, import/export workflow.
- Current gaps: minimal automated test coverage and non-typed error handling.
- Treat these as iterative improvement areas, not blockers for normal feature work.
