---
name: create-financier-feature
description: Scaffolds a full Financier feature using this repo's architecture: domain model, local repository (SharedPreferences JSON cache), ChangeNotifier ViewModel, list + add/edit screens, DI registration in app_providers.dart, and routes in app_router.dart. Keywords: scaffold, feature, crud, provider, go_router, repository, viewmodel.
---

# Skill: /create-financier-feature

**Version**: 1.0  
**Last Updated**: March 17, 2026  
**Time Saved**: ~60-90 minutes  
**Complexity**: High  
**Priority**: ⭐⭐⭐⭐⭐

## 🎯 Purpose
Create a complete, working feature aligned with Financier's current stack:
- `provider` + `ChangeNotifier`
- `go_router` route wiring
- local-first persistence via `LocalStorageService`
- repository cache + JSON serialization pattern

## 📥 Input Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `feature-name` | string | Yes | snake_case feature name (e.g. `goals`) |
| `entity-name` | string | Yes | PascalCase entity name (e.g. `Goal`) |
| `has-amounts` | boolean | No | Adds currency fields and `intl` formatting defaults |
| `route-scope` | enum | No | `tab` or `nested` (default `nested`) |

## 📤 Output Files
- `lib/domain/models/{feature_name_singular}.dart`
- `lib/data/repositories/{feature_name_singular}_repository.dart`
- `lib/ui/feature/{feature_name}/{feature_name}_view_model.dart`
- `lib/ui/feature/{feature_name}/{feature_name}_screen.dart`
- `lib/ui/feature/{feature_name}/add_edit_{feature_name_singular}_screen.dart`
- Updates `lib/di/app_providers.dart`
- Updates `lib/routing/app_router.dart`

## 🔧 Implementation Steps
1. Validate naming and confirm files do not already exist.
2. Create domain model with `copyWith`, `toJson`, `fromJson`.
3. Create repository with private `_cache`, `_load()`, `_persist()`, CRUD methods, immutable read getter.
4. Create ViewModel with `_isLoading`, `_error`, and CRUD async actions.
5. Create list screen + add/edit screen using existing styling and form patterns.
6. Wire DI in `app_providers.dart` with `Provider` + `ChangeNotifierProvider`.
7. Wire routes in `app_router.dart` with add/edit paths.
8. Run `dart format .` and `flutter analyze`.

## ✅ Guardrails
- Never use `ProxyProvider` for `ChangeNotifier` classes.
- Keep business logic out of widgets.
- Keep storage/network calls out of screens.
- Use existing app patterns (`*_view_model.dart`, `add_edit_*_screen.dart`).
- Do not introduce cloud sync/auth dependencies in this skill.

## 🧪 Success Criteria
- Feature compiles and is navigable.
- Route names are unique and follow existing naming style.
- DI registration order remains valid.
- `flutter analyze` reports no issues.

## 🚫 When NOT to Use
- One-off small UI tweak in an existing screen.
- Refactoring only (use targeted skills).
- Complex cross-feature workflows needing multiple repositories at once.

## 🔗 Related Skills
- `/create-domain-model`
- `/create-local-repository`
- `/create-feature-viewmodel`
- `/wire-di-routing`
- `/financier-quality-audit`
