---
name: financier-quality-audit
description: Performs a full Financier quality audit: architecture boundaries, provider/routing integrity, persistence consistency, analyzer/test gates, and UX readiness checks for manual-finance workflows. Keywords: audit, quality, analyze, provider, routing, persistence, checklist.
---

# Skill: /financier-quality-audit

**Version**: 1.0  
**Last Updated**: March 17, 2026  
**Time Saved**: ~30-50 minutes  
**Complexity**: Medium  
**Priority**: ⭐⭐⭐⭐⭐

## 🎯 Purpose
Provide a repeatable release-readiness audit for this app's real constraints:
manual data entry, recurring transactions, 50/30/20 budgeting, debt tracking, and tabbed navigation.

## 📥 Input Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `scope` | enum | No | `full` (default), `feature`, `file` |
| `targets` | array | No | specific features/files to audit |
| `run-tests` | boolean | No | run tests if available |
| `include-ux-checks` | boolean | No | include manual workflow validation |

## 📤 Output
- Audit report grouped by: architecture, data consistency, navigation, quality gates, and risks.
- Optional patch suggestions/fixes for critical issues.

## 🔧 Audit Checklist
1. **Architecture boundaries**: no business logic in widgets; no storage/service calls in UI.
2. **State management**: ChangeNotifier usage and notify/load/error flow consistency.
3. **Persistence**: repository cache + persist sequence, JSON safety, key/version stability.
4. **Routing/DI**: route resolution, unique names, provider availability.
5. **Build quality**: `dart format .`, `flutter analyze`, tests if requested.
6. **Manual UX pass**: add account → add income → add recurring bill → verify budget/debt/dashboard updates.

## ✅ Guardrails
- Do not rewrite architecture during audit unless requested.
- Report non-blocking items separately from ship blockers.
- Keep fixes minimal and scoped to observed failures.

## 🧪 Success Criteria
- Clear pass/fail status with actionable blockers.
- Analyzer is clean or blockers explicitly listed.
- Critical user workflows are validated end-to-end.

## 🚫 When NOT to Use
- Rapid brainstorming sessions.
- Small isolated styling tweaks.
