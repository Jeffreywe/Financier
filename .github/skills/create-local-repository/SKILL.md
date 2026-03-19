---
name: create-local-repository
description: Builds Financier-style local repositories backed by LocalStorageService and in-memory cache, including CRUD, computed totals, and optional filtered query methods. Keywords: repository, shared_preferences, cache, local storage, crud.
---

# Skill: /create-local-repository

**Version**: 1.0  
**Last Updated**: March 17, 2026  
**Time Saved**: ~30-45 minutes  
**Complexity**: Medium  
**Priority**: ⭐⭐⭐⭐⭐

## 🎯 Purpose
Create repository files in `lib/data/repositories/` following current implementation style:
- private list cache
- eager `_load()` in constructor
- CRUD with `_persist()`
- immutable list getter

## 📥 Input Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `entity-name` | string | Yes | Model class name |
| `file-name` | string | Yes | repository file name |
| `storage-read-method` | string | Yes | LocalStorageService read method |
| `storage-write-method` | string | Yes | LocalStorageService write method |
| `queries` | array | No | Optional query methods to add |
| `computed` | array | No | Optional aggregate getters |

## 📤 Output Files
- Creates: `lib/data/repositories/{file-name}.dart`
- Optionally updates: `lib/data/services/local_storage_service.dart`

## 🔧 Implementation Steps
1. Validate model has `toJson`/`fromJson`.
2. Generate repository constructor + `_load()`.
3. Add immutable `all` getter.
4. Add CRUD methods with persistence.
5. Add optional computed/query methods.
6. Ensure sort order is explicit where required.

## ✅ Guardrails
- Repositories do not depend on UI classes.
- No widget/business presentation logic in repository.
- Avoid exposing mutable cache directly.
- Every mutating method persists storage.

## 🧪 Success Criteria
- Repository methods are deterministic and compile.
- Data remains consistent after add/update/delete operations.
- Existing ViewModel pattern can use repository directly.

## 🚫 When NOT to Use
- Network/API repositories (different concern).
- One-off transformation best kept inside a ViewModel.
