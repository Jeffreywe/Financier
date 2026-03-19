---
name: wire-di-routing
description: Safely wires new repositories/ViewModels into app_providers.dart and registers routes in app_router.dart using this project's tab+nested GoRouter structure. Keywords: di, providers, go_router, routes, registration.
---

# Skill: /wire-di-routing

**Version**: 1.0  
**Last Updated**: March 17, 2026  
**Time Saved**: ~15-25 minutes  
**Complexity**: Medium  
**Priority**: ⭐⭐⭐⭐⭐

## 🎯 Purpose
Centralize and de-risk edits to the two highest-friction files:
- `lib/di/app_providers.dart`
- `lib/routing/app_router.dart`

## 📥 Input Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `repository-registrations` | array | No | Provider registrations to add |
| `viewmodel-registrations` | array | Yes | ChangeNotifierProvider registrations |
| `route-branch` | enum | Yes | `dashboard/accounts/transactions/budget/debt` or `nested-only` |
| `routes` | array | Yes | route entries with path, name, builder |

## 📤 Output Files
- Updates: `lib/di/app_providers.dart`
- Updates: `lib/routing/app_router.dart`

## 🔧 Implementation Steps
1. Add required imports with proper grouping.
2. Register repositories before ViewModels.
3. Register each ViewModel with `ChangeNotifierProvider`.
4. Insert routes in the correct branch with add/edit nested routes as needed.
5. Validate unique route names and path collisions.

## ✅ Guardrails
- Never use `ProxyProvider` for `ChangeNotifier` classes.
- Preserve existing shell route and bottom-nav branch ordering.
- Avoid builder placeholders like unused underscore spam that trigger lint noise.

## 🧪 Success Criteria
- App launches and routes resolve.
- Provider lookups succeed at runtime.
- No analyzer issues in DI/router files.

## 🚫 When NOT to Use
- Refactoring business logic inside feature files.
- Rewriting overall navigation architecture.
