# Financier Skills Reference

This document lists all repository-specific skills in `.github/skills/`, what each skill does, when to use it, and how to use it safely.

## Skill Catalog

### 1) `/create-financier-feature`
- **Path**: `.github/skills/create-financier-feature/SKILL.md`
- **Use for**: End-to-end feature scaffolding (model + repository + ViewModel + screens + DI + routes).
- **Best when**: You are adding a new product feature from scratch (for example: goals, reports, settings section).
- **Do not use when**: You are only editing one existing file or doing a tiny UI fix.
- **Typical invocation inputs**:
  - `feature-name`
  - `entity-name`
  - `route-scope`
- **Expected result**: A compilable feature skeleton wired into the app.

### 2) `/create-domain-model`
- **Path**: `.github/skills/create-domain-model/SKILL.md`
- **Use for**: New/updated domain entities in `lib/domain/models`.
- **Best when**: A feature needs new fields, enums, JSON mapping, or copyWith changes.
- **Do not use when**: Data belongs only to temporary widget state.
- **Typical invocation inputs**:
  - `model-name`
  - `file-name`
  - `fields`
  - `enums`
- **Expected result**: Stable model API used by repositories/ViewModels.

### 3) `/create-local-repository`
- **Path**: `.github/skills/create-local-repository/SKILL.md`
- **Use for**: Local-first repositories with cache + SharedPreferences persistence.
- **Best when**: Adding a persisted entity that follows current `LocalStorageService` pattern.
- **Do not use when**: Building network/API integrations.
- **Typical invocation inputs**:
  - `entity-name`
  - `storage-read-method`
  - `storage-write-method`
  - optional `queries`/`computed`
- **Expected result**: Deterministic CRUD repository with immutable read access.

### 4) `/create-feature-viewmodel`
- **Path**: `.github/skills/create-feature-viewmodel/SKILL.md`
- **Use for**: `ChangeNotifier` ViewModels with consistent loading/error handling.
- **Best when**: New feature screen needs repository-backed state and actions.
- **Do not use when**: Local ephemeral screen-only state is enough.
- **Typical invocation inputs**:
  - `feature-name`
  - `viewmodel-name`
  - `repository-type`
  - `actions`
- **Expected result**: A ViewModel ready for `context.watch/read` usage.

### 5) `/wire-di-routing`
- **Path**: `.github/skills/wire-di-routing/SKILL.md`
- **Use for**: Safe edits to DI and GoRouter registration.
- **Best when**: Any new feature/repository/viewmodel needs app-level wiring.
- **Do not use when**: Refactoring business rules inside feature classes.
- **Typical invocation inputs**:
  - `repository-registrations`
  - `viewmodel-registrations`
  - `route-branch`
  - `routes`
- **Expected result**: Working providers and reachable routes with no collisions.

### 6) `/financier-quality-audit`
- **Path**: `.github/skills/financier-quality-audit/SKILL.md`
- **Use for**: Release-readiness checks across architecture, persistence, routing, and UX flows.
- **Best when**: Before shipping or after large changes across multiple features.
- **Do not use when**: You only changed a single label/color.
- **Typical invocation inputs**:
  - `scope`
  - `targets`
  - `run-tests`
  - `include-ux-checks`
- **Expected result**: Pass/fail report with actionable blockers.

## Recommended Usage Flow

For most new features in this app, use skills in this sequence:
1. `/create-domain-model`
2. `/create-local-repository`
3. `/create-feature-viewmodel`
4. `/create-financier-feature` (or use this first for full scaffold)
5. `/wire-di-routing`
6. `/financier-quality-audit`

## Repo-Specific Guardrails (Must Follow)

- Use `ChangeNotifierProvider` for ViewModels; avoid `ProxyProvider` for ChangeNotifier types.
- Keep architecture boundaries strict: UI → ViewModel → Repository → Storage.
- Keep persistence local-first unless explicitly expanding architecture.
- Keep route names unique and consistent with current naming scheme.
- Run `dart format .` and `flutter analyze` after skill-generated edits.

## Notes

- These skills are intentionally tailored to the current Financier codebase patterns and file layout.
- If architecture changes materially (for example moving from SharedPreferences to database), update the relevant skill docs first to avoid stale scaffolding behavior.
