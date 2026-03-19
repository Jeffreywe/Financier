import 'package:financier/data/repositories/goals_repository.dart';
import 'package:financier/data/repositories/goal_milestones_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/domain/models/goal_milestone.dart';
import 'package:financier/domain/models/savings_goal.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class GoalsViewModel extends ChangeNotifier {
  final GoalsRepository _goalsRepo;
  final GoalMilestonesRepository _milestonesRepo;
  final TransactionsRepository _transactionsRepo;

  bool _isLoading = false;
  String? _error;
  String? _selectedGoalId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedGoalId => _selectedGoalId;

  GoalsViewModel(this._goalsRepo, this._milestonesRepo, this._transactionsRepo) {
    _goalsRepo.addListener(_onRepositoryChanged);
    _milestonesRepo.addListener(_onRepositoryChanged);
    _transactionsRepo.addListener(_onRepositoryChanged);
  }

  List<SavingsGoal> get all => _goalsRepo.all;
  List<SavingsGoal> get activeGoals => _goalsRepo.activeGoals;
  double get totalTargetAmount => _goalsRepo.totalTargetAmount;
  double get totalCurrentAmount => _goalsRepo.totalCurrentAmount;
  double get totalRemaining => totalTargetAmount - totalCurrentAmount;

  SavingsGoal? get selectedGoal {
    if (_selectedGoalId == null) return null;
    return _goalsRepo.findById(_selectedGoalId!);
  }

  List<SavingsGoal> goalsForAccount(String accountId) {
    return _goalsRepo.goalsForAccount(accountId);
  }

  /// Load all goals (used on feature init)
  Future<void> loadGoals() async {
    try {
      _setLoading(true);
      _error = null;
      // Goals are loaded from cache by the repository
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load goals: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new savings goal
  Future<void> createGoal({
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime startDate,
    required DateTime dueDate,
    String? linkedAccountId,
    bool isRecurringContribution = false,
    double? recurringAmount,
    ContributionFrequency recurringFrequency = ContributionFrequency.none,
    bool autoGenerateTransaction = false,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final goal = SavingsGoal(
        id: const Uuid().v4(),
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        linkedAccountId: linkedAccountId,
        startDate: startDate,
        dueDate: dueDate,
        status: GoalStatus.active,
        isRecurringContribution: isRecurringContribution,
        recurringAmount: recurringAmount,
        recurringFrequency: recurringFrequency,
        autoGenerateTransaction: autoGenerateTransaction,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _goalsRepo.add(goal);

      // Create default milestones at 25%, 50%, 75%
      await _createDefaultMilestones(goal);

      // Create recurring transaction if requested
      if (isRecurringContribution &&
          autoGenerateTransaction &&
          recurringAmount != null &&
          recurringAmount > 0) {
        await _createRecurringContributionTransaction(goal);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to create goal: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createDefaultMilestones(SavingsGoal goal) async {
    try {
      final now = DateTime.now();
      final milestones = [
        GoalMilestone(
          id: const Uuid().v4(),
          goalId: goal.id,
          name: '25% Complete',
          targetAmount: goal.targetAmount * 0.25,
          completedAt: goal.currentAmount >= goal.targetAmount * 0.25
              ? now
              : null,
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GoalMilestone(
          id: const Uuid().v4(),
          goalId: goal.id,
          name: '50% Complete',
          targetAmount: goal.targetAmount * 0.50,
          completedAt: goal.currentAmount >= goal.targetAmount * 0.50
              ? now
              : null,
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GoalMilestone(
          id: const Uuid().v4(),
          goalId: goal.id,
          name: '75% Complete',
          targetAmount: goal.targetAmount * 0.75,
          completedAt: goal.currentAmount >= goal.targetAmount * 0.75
              ? now
              : null,
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final milestone in milestones) {
        await _milestonesRepo.add(milestone);
      }
    } catch (e) {
      // Log milestone creation error but don't fail the goal creation
      debugPrint('Error creating default milestones: $e');
    }
  }

  Future<void> _createRecurringContributionTransaction(SavingsGoal goal) async {
    try {
      final recurrenceFrequency = _convertContributionToRecurrence(
        goal.recurringFrequency,
      );

      final transaction = Transaction(
        id: const Uuid().v4(),
        title: '${goal.name} - Recurring Contribution',
        amount: goal.recurringAmount ?? 0,
        type: TransactionType.expense,
        categoryId: 'cat_savings_transfer',
        date: goal.startDate,
        isRecurring: true,
        recurrenceFrequency: recurrenceFrequency,
        goalId: goal.id,
      );

      await _transactionsRepo.add(transaction);
    } catch (e) {
      // Log transaction creation error but don't fail the goal creation
      debugPrint('Error creating recurring transaction: $e');
    }
  }

  RecurrenceFrequency _convertContributionToRecurrence(
    ContributionFrequency freq,
  ) {
    switch (freq) {
      case ContributionFrequency.weekly:
        return RecurrenceFrequency.weekly;
      case ContributionFrequency.biweekly:
        return RecurrenceFrequency.biweekly;
      case ContributionFrequency.monthly:
        return RecurrenceFrequency.monthly;
      case ContributionFrequency.quarterly:
        return RecurrenceFrequency.quarterly;
      case ContributionFrequency.annually:
        return RecurrenceFrequency.annually;
      case ContributionFrequency.none:
        return RecurrenceFrequency.none;
    }
  }

  /// Update an existing savings goal
  Future<void> updateGoal(SavingsGoal goal) async {
    try {
      _setLoading(true);
      _error = null;

      final updated = goal.copyWith(updatedAt: DateTime.now());
      await _goalsRepo.update(updated);
      await _syncMilestonesForBalance(
        goalId: updated.id,
        currentAmount: updated.currentAmount,
        completionDate: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update goal: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a savings goal (and all associated milestones)
  Future<void> deleteGoal(String goalId) async {
    try {
      _setLoading(true);
      _error = null;

      // Delete all transactions linked to this goal
      await _transactionsRepo.deleteForGoal(goalId);

      // Delete all milestones for this goal
      await _milestonesRepo.deleteForGoal(goalId);

      // Delete the goal
      await _goalsRepo.delete(goalId);

      if (_selectedGoalId == goalId) {
        _selectedGoalId = null;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete goal: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle goal status (active/paused/completed)
  Future<void> toggleGoalStatus(String goalId, GoalStatus newStatus) async {
    try {
      final goal = _goalsRepo.findById(goalId);
      if (goal == null) {
        _error = 'Goal not found';
        return;
      }

      final updated = goal.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _goalsRepo.update(updated);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update goal status: ${e.toString()}';
    }
  }

  /// Add a contribution transaction to a goal.
  /// When [isPaid] is false the transaction is recorded but [currentAmount]
  /// is NOT updated until the contribution is marked paid.
  Future<void> addContribution({
    required String goalId,
    required double amount,
    required DateTime date,
    String? title,
    String categoryId = 'cat_savings_transfer',
    String? accountId,
    bool isRecurring = false,
    RecurrenceFrequency recurrenceFrequency = RecurrenceFrequency.none,
    bool isPaid = false,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final goal = _goalsRepo.findById(goalId);
      if (goal == null) {
        _error = 'Goal not found';
        return;
      }

      final transaction = Transaction(
        id: const Uuid().v4(),
        title: title ?? '${goal.name} Contribution',
        amount: amount,
        type: TransactionType.expense,
        categoryId: categoryId,
        date: date,
        isRecurring: isRecurring,
        recurrenceFrequency: recurrenceFrequency,
        accountId: accountId,
        goalId: goalId,
        isPaid: isPaid,
      );

      await _transactionsRepo.add(transaction);

      if (isPaid) {
        await _applyPaidContribution(goal, amount, date);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to add contribution: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Toggles a contribution between paid and unpaid, adjusting [currentAmount].
  Future<void> toggleContributionPaid(
    String transactionId,
    String goalId,
  ) async {
    try {
      _setLoading(true);
      _error = null;

      final txn = _transactionsRepo.findById(transactionId);
      final goal = _goalsRepo.findById(goalId);
      if (txn == null || goal == null) return;

      final nowPaid = !txn.isPaid;
      await _transactionsRepo.update(txn.copyWith(isPaid: nowPaid));

      if (nowPaid) {
        await _applyPaidContribution(goal, txn.amount, txn.date);
      } else {
        final newAmount = (goal.currentAmount - txn.amount).clamp(
          0.0,
          goal.targetAmount,
        );
        await _goalsRepo.update(
          goal.copyWith(currentAmount: newAmount, updatedAt: DateTime.now()),
        );
        final milestones = _milestonesRepo.milestonesForGoal(goalId);
        for (final m in milestones) {
          if (m.isCompleted && newAmount < m.targetAmount) {
            await _milestonesRepo.update(m.copyWith(clearCompletedAt: true));
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update contribution: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Updates all fields of a contribution and reconciles [currentAmount].
  Future<void> updateContribution({
    required String transactionId,
    required String goalId,
    required String title,
    required double amount,
    required DateTime date,
    required String categoryId,
    required String? accountId,
    required bool isRecurring,
    required RecurrenceFrequency recurrenceFrequency,
    required bool isPaid,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final existing = _transactionsRepo.findById(transactionId);
      final goal = _goalsRepo.findById(goalId);
      if (existing == null || goal == null) return;

      final wasApplied = existing.isPaid;
      final oldAmount = existing.amount;

      await _transactionsRepo.update(
        existing.copyWith(
          title: title,
          amount: amount,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          clearAccountId: accountId == null,
          isRecurring: isRecurring,
          recurrenceFrequency: recurrenceFrequency,
          isPaid: isPaid,
        ),
      );

      // Reconcile currentAmount: remove old contribution, add new if paid
      double adjusted = goal.currentAmount;
      if (wasApplied) adjusted -= oldAmount;
      if (isPaid) adjusted += amount;
      final newAmount = adjusted.clamp(0.0, goal.targetAmount);
      await _goalsRepo.update(
        goal.copyWith(currentAmount: newAmount, updatedAt: DateTime.now()),
      );

      // Re-evaluate all milestones
      final milestones = _milestonesRepo.milestonesForGoal(goalId);
      for (final m in milestones) {
        if (!m.isCompleted && newAmount >= m.targetAmount) {
          await _milestonesRepo.update(m.copyWith(completedAt: date));
        } else if (m.isCompleted && newAmount < m.targetAmount) {
          await _milestonesRepo.update(m.copyWith(clearCompletedAt: true));
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update contribution: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _applyPaidContribution(
    SavingsGoal goal,
    double amount,
    DateTime date,
  ) async {
    final newAmount = (goal.currentAmount + amount).clamp(
      0.0,
      goal.targetAmount,
    );
    await _goalsRepo.update(
      goal.copyWith(currentAmount: newAmount, updatedAt: DateTime.now()),
    );
    final milestones = _milestonesRepo.milestonesForGoal(goal.id);
    for (final m in milestones) {
      if (!m.isCompleted && newAmount >= m.targetAmount) {
        await _milestonesRepo.update(m.copyWith(completedAt: date));
      }
    }
  }

  /// Get estimated completion date for a goal
  DateTime? getEstimatedCompletionDate(String goalId) {
    return _goalsRepo.estimateCompletionDate(goalId);
  }

  Future<void> _syncMilestonesForBalance({
    required String goalId,
    required double currentAmount,
    required DateTime completionDate,
  }) async {
    final milestones = _milestonesRepo.milestonesForGoal(goalId);
    for (final milestone in milestones) {
      if (!milestone.isCompleted && currentAmount >= milestone.targetAmount) {
        await _milestonesRepo.update(
          milestone.copyWith(completedAt: completionDate),
        );
      } else if (milestone.isCompleted && currentAmount < milestone.targetAmount) {
        await _milestonesRepo.update(milestone.copyWith(clearCompletedAt: true));
      }
    }
  }

  /// Select a goal for viewing
  void selectGoal(String goalId) {
    _selectedGoalId = goalId;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedGoalId = null;
    notifyListeners();
  }

  /// Force UI refresh when repositories are updated externally.
  void refresh() {
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _onRepositoryChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _goalsRepo.removeListener(_onRepositoryChanged);
    _milestonesRepo.removeListener(_onRepositoryChanged);
    _transactionsRepo.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
