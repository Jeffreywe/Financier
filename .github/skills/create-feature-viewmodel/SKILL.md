---
name: create-feature-viewmodel
description: Creates Financier ChangeNotifier ViewModels with consistent loading/error flow, CRUD actions, and repository integration. Keywords: viewmodel, changenotifier, provider, state management, loading, error.
---

# Skill: /create-feature-viewmodel

**Version**: 1.0  
**Last Updated**: March 17, 2026  
**Time Saved**: ~25-40 minutes  
**Complexity**: Medium  
**Priority**: ⭐⭐⭐⭐⭐

## 🎯 Purpose
Generate ViewModels that match current patterns used across Accounts, Transactions, Budget, Debt, and Dashboard.

## 📥 Input Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `feature-name` | string | Yes | snake_case feature name |
| `viewmodel-name` | string | Yes | PascalCase class name |
| `repository-type` | string | Yes | Injected repository class |
| `actions` | array | Yes | Methods to generate (add/update/delete/load/etc.) |
| `state-fields` | array | No | Additional VM state fields |

## 📤 Output Files
- Creates: `lib/ui/feature/{feature-name}/{feature-name}_view_model.dart`

## 🔧 Implementation Steps
1. Create `ChangeNotifier` class with repository injection.
2. Add `_isLoading`, `_error`, getters, and clearError.
3. Generate async actions with `try/catch/finally` and notifications.
4. Add common find/filter/group helpers when requested.
5. Keep user-facing error messages concise and actionable.

## ✅ Guardrails
- Do not call `LocalStorageService` directly from ViewModel.
- Ensure every async mutating action toggles loading and notifies listeners.
- No route navigation inside ViewModel.

## 🧪 Success Criteria
- ViewModel compiles and integrates into `ChangeNotifierProvider`.
- Screens can consume it with `context.watch/read`.
- No analyzer warnings from flow-control/state handling patterns.

## 🚫 When NOT to Use
- Stateless/pure computed helper classes.
- Very simple one-screen local state better handled by `StatefulWidget`.
