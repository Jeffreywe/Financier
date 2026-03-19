import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/savings_goal.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';

class GoalsRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  final TransactionsRepository _transactionsRepository;
  List<SavingsGoal> _cache = [];

  GoalsRepository(this._storage, this._transactionsRepository) {
    _load();
  }

  void _load() {
    _cache = _storage.readGoals().map(SavingsGoal.fromJson).toList();
    notifyListeners();
  }

  List<SavingsGoal> get all => List.unmodifiable(_cache);

  SavingsGoal? findById(String id) {
    try {
      return _cache.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<SavingsGoal> goalsForAccount(String accountId) {
    return _cache.where((g) => g.linkedAccountId == accountId).toList();
  }

  List<SavingsGoal> get activeGoals {
    return _cache
        .where((g) => g.status == GoalStatus.active && !g.isCompleted)
        .toList();
  }

  double get totalTargetAmount {
    return _cache.fold(0.0, (sum, g) => sum + g.targetAmount);
  }

  double get totalCurrentAmount {
    return _cache.fold(0.0, (sum, g) => sum + g.currentAmount);
  }

  /// Calculates the estimated completion date based on contribution velocity.
  /// Uses average monthly contribution from *paid* linked transactions.
  /// Falls back to the goal's recurring contribution settings when no paid
  /// history exists yet.
  DateTime? estimateCompletionDate(String goalId) {
    final goal = findById(goalId);
    if (goal == null || goal.isCompleted) return null;
    if (goal.remainingAmount <= 0) return DateTime.now();

    // Only paid contributions count toward velocity
    final paidTxns = _transactionsRepository.all
        .where((t) => t.goalId == goalId && t.amount > 0 && t.isPaid)
        .toList();

    double avgPerMonth;

    if (paidTxns.length >= 2) {
      // Sufficient history — compute from actual velocity
      final total = paidTxns.fold(0.0, (sum, t) => sum + t.amount);
      final earliest = paidTxns.map((t) => t.date).reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
      final latest = paidTxns.map((t) => t.date).reduce(
        (a, b) => a.isAfter(b) ? a : b,
      );
      final days = latest.difference(earliest).inDays;
      if (days <= 0) return null;
      avgPerMonth = (total / days) * 30.44;
    } else {
      final recurringTemplates = _transactionsRepository.all
          .where(
            (t) =>
                t.goalId == goalId &&
                t.amount > 0 &&
                t.isRecurring &&
                t.recurrenceFrequency != RecurrenceFrequency.none,
          )
          .toList();

      final recurringVelocity = recurringTemplates.fold<double>(
        0,
        (sum, t) =>
            sum +
            _monthlyEquivalentFromRecurrence(
              t.recurrenceFrequency,
              t.amount,
            ),
      );

      if (recurringVelocity > 0) {
        // Planned recurring linked contributions should drive projection
        // even if goal-level recurring settings are disabled.
        avgPerMonth = recurringVelocity;
      } else if (goal.isRecurringContribution &&
          goal.recurringAmount != null &&
          goal.recurringAmount! > 0) {
        // Legacy fallback from goal-level settings
        avgPerMonth = _monthlyEquivalent(
          goal.recurringFrequency,
          goal.recurringAmount!,
        );
      } else {
        return null;
      }
    }

    if (avgPerMonth <= 0) return null;

    final monthsNeeded = goal.remainingAmount / avgPerMonth;
    return DateTime.now().add(Duration(days: (monthsNeeded * 30.44).toInt()));
  }

  double _monthlyEquivalent(ContributionFrequency freq, double amount) {
    switch (freq) {
      case ContributionFrequency.weekly:
        return amount * 52 / 12;
      case ContributionFrequency.biweekly:
        return amount * 26 / 12;
      case ContributionFrequency.monthly:
        return amount;
      case ContributionFrequency.quarterly:
        return amount / 3;
      case ContributionFrequency.annually:
        return amount / 12;
      case ContributionFrequency.none:
        return 0;
    }
  }

  double _monthlyEquivalentFromRecurrence(
    RecurrenceFrequency freq,
    double amount,
  ) {
    switch (freq) {
      case RecurrenceFrequency.weekly:
        return amount * 52 / 12;
      case RecurrenceFrequency.biweekly:
        return amount * 26 / 12;
      case RecurrenceFrequency.monthly:
        return amount;
      case RecurrenceFrequency.quarterly:
        return amount / 3;
      case RecurrenceFrequency.annually:
        return amount / 12;
      case RecurrenceFrequency.none:
        return 0;
    }
  }

  Future<void> add(SavingsGoal goal) async {
    _cache.add(goal);
    await _persist();
    notifyListeners();
  }

  Future<void> update(SavingsGoal goal) async {
    final idx = _cache.indexWhere((g) => g.id == goal.id);
    if (idx == -1) return;
    _cache[idx] = goal;
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((g) => g.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<SavingsGoal> goals) async {
    _cache = List<SavingsGoal>.from(goals);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _storage.writeGoals(_cache.map((g) => g.toJson()).toList());
}
