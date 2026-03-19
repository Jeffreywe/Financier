---
name: create-domain-model
description: Creates or updates Financier domain model files with immutable fields, copyWith, JSON serialization, enum label extensions, and model-level helpers used by repositories/ViewModels. Keywords: model, serialization, copyWith, enum, json, domain.
---

# Skill: /create-domain-model

**Version**: 1.0  
**Last Updated**: March 17, 2026  
**Time Saved**: ~20-35 minutes  
**Complexity**: Medium  
**Priority**: ⭐⭐⭐⭐

## 🎯 Purpose
Standardize model creation and model updates in `lib/domain/models/` so all entities are consistent with current repo patterns.

## 📥 Input Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `model-name` | string | Yes | PascalCase model name |
| `file-name` | string | Yes | snake_case file name |
| `fields` | array | Yes | List of fields with types/nullability |
| `enums` | array | No | Enum names and values |
| `helpers` | array | No | Derived getters or model helpers |

## 📤 Output Files
- Creates or updates: `lib/domain/models/{file-name}.dart`

## 🔧 Implementation Steps
1. Generate enum(s) first (if provided).
2. Generate immutable model class with constructor and final fields.
3. Add `copyWith` with optional clear flags for nullable fields if needed.
4. Add `toJson` and `fromJson` with DateTime/enum-safe handling.
5. Add label extension(s) for enums when UI-facing text is required.
6. Preserve existing behavior if file already exists.

## ✅ Guardrails
- Keep domain model free from Flutter dependencies.
- Avoid service/repository calls in model classes.
- Keep serialization keys stable unless explicitly migrating storage.
- Use explicit types; avoid `dynamic` in model API.

## 🧪 Success Criteria
- Model compiles and serializes/deserializes correctly.
- Enum conversions are safe (`values.byName(...)` with fallback when needed).
- Existing repository code can consume the model without additional rewrites.

## 🚫 When NOT to Use
- Pure UI state that belongs in a ViewModel.
- Temporary form-only objects not persisted or shared.
