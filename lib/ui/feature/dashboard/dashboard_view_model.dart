import 'package:financier/data/repositories/accounts_repository.dart';
import 'package:financier/data/repositories/debt_repository.dart';
import 'package:financier/data/repositories/goal_milestones_repository.dart';
import 'package:financier/data/repositories/goals_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';

/// A single line-item within a future outlook period.
class OutlookItem {
  final String transactionId;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final bool isPaid;

  const OutlookItem({
    required this.transactionId,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.isPaid,
  });
}

/// Aggregated income/expense projection for a date range or calendar month.
class OutlookPeriod {
  final String label;

  /// The start of the period (midnight).
  final DateTime from;

  /// The end of the period (midnight of last day). Null for whole-month periods.
  final DateTime? to;

  final double income;
  final double expenses;
  final bool showAccountBalanceLabel;

  /// Line items sorted chronologically.
  final List<OutlookItem> items;

  const OutlookPeriod({
    required this.label,
    required this.from,
    this.to,
    required this.income,
    required this.expenses,
    required this.items,
    this.showAccountBalanceLabel = false,
  });

  double get net => income - expenses;
}

class DashboardViewModel extends ChangeNotifier {
  final TransactionsRepository _txRepo;
  final AccountsRepository _accountsRepo;
  final DebtRepository _debtRepo;
  final GoalsRepository _goalsRepo;
  final GoalMilestonesRepository _milestonesRepo;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DashboardViewModel(
    this._txRepo,
    this._accountsRepo,
    this._debtRepo,
    this._goalsRepo,
    this._milestonesRepo,
  ) {
    _txRepo.addListener(_onRepositoryChanged);
    _accountsRepo.addListener(_onRepositoryChanged);
    _debtRepo.addListener(_onRepositoryChanged);
    _goalsRepo.addListener(_onRepositoryChanged);
    _milestonesRepo.addListener(_onRepositoryChanged);
  }

  DateTime get _now => DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  List<Transaction> get _thisMonth => _txRepo.forMonthIncludingRecurring(
    _selectedMonth.year,
    _selectedMonth.month,
  );

  double get monthlyIncome => _thisMonth
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get monthlyExpenses => _thisMonth
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get leftToBudget => monthlyIncome - monthlyExpenses;

  double get totalAccountBalance => _accountsRepo.totalBalance;

  double get totalDebt => _debtRepo.totalBalance;

  // Calendar data for current month
  List<OutlookItem> get currentMonthCalendarItems {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final txns = _txRepo.forMonthIncludingRecurring(year, month);
    final items = txns
        .map(
          (t) => OutlookItem(
            transactionId: t.id,
            title: t.title,
            amount: t.amount,
            type: t.type,
            date: t.date,
            isPaid: _txRepo.isOccurrencePaid(t.id, t.date),
          ),
        )
        .toList();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  List<OutlookItem> currentMonthItemsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return currentMonthCalendarItems.where((item) {
      final d = DateTime(item.date.year, item.date.month, item.date.day);
      return d == normalized;
    }).toList();
  }

  List<OutlookItem> get allNotesItems {
    final notes = _txRepo.all
        .where((t) => t.type == TransactionType.note)
        .map(
          (t) => OutlookItem(
            transactionId: t.id,
            title: t.title,
            amount: t.amount,
            type: t.type,
            date: t.date,
            isPaid: _txRepo.isOccurrencePaid(t.id, t.date),
          ),
        )
        .toList();
    notes.sort((a, b) => a.date.compareTo(b.date));
    return notes;
  }

  // 5 most recent *non-future* transactions across all types
  List<Transaction> get recentTransactions {
    final now = _now;
    return _txRepo.all
        .where((t) => t.type != TransactionType.note && !t.date.isAfter(now))
        .take(5)
        .toList();
  }

  // Upcoming recurring bills/income in next 7 days
  List<({Transaction transaction, DateTime nextDate})> get upcomingItems {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _txRepo.upcomingRecurring(
      from: now,
      to: now.add(const Duration(days: 7)),
    );

    final overdueUnpaid = _txRepo.all
        .where(
          (t) =>
              t.type != TransactionType.note &&
              t.date.isBefore(today) &&
              !_txRepo.isOccurrencePaid(t.id, t.date),
        )
        .map((t) => (transaction: t, nextDate: t.date));

    final merged = [...overdueUnpaid, ...upcoming];
    merged.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return merged;
  }

  // ── Future Outlook ────────────────────────────────────────────────────────

  /// Two outlook periods based on paycheck dates: from today until first
  /// paycheck, then subsequent paycheck to paycheck. If no recurring income
  /// found, falls back to 14-day periods.
  List<OutlookPeriod> get biweeklyOutlook {
    final today = DateTime(_now.year, _now.month, _now.day);
    final paycheck1 = _getNextPaycheckDate();

    if (paycheck1 == null) {
      // Fallback to fixed 14-day periods: previous, current, and next 1..6
      final currentFrom = today.subtract(const Duration(days: 13));
      final currentTo = today.add(const Duration(days: 13));
      final previousFrom = currentFrom.subtract(const Duration(days: 14));
      final previousTo = currentFrom.subtract(const Duration(days: 1));

      final periods = <OutlookPeriod>[
        _buildBiweeklyPeriod(
          label: 'Previous',
          from: previousFrom,
          to: previousTo,
        ),
        _buildBiweeklyPeriod(
          label: 'Current',
          from: currentFrom,
          to: currentTo,
          includeCarryoverUnpaidBeforeFrom: true,
        ),
      ];

      var nextFrom = today.add(const Duration(days: 14));
      for (var i = 1; i <= 6; i++) {
        final nextTo = nextFrom.add(const Duration(days: 13));
        periods.add(
          _buildBiweeklyPeriod(label: 'Next $i', from: nextFrom, to: nextTo),
        );
        nextFrom = nextFrom.add(const Duration(days: 14));
      }

      return periods;
    }

    // paycheck1 is the next paycheck date
    final previousPaycheck =
        _getPreviousPaycheckDate(today) ??
        paycheck1.subtract(const Duration(days: 14));
    final previousPreviousPaycheck =
        _getPreviousPaycheckDate(
          previousPaycheck.subtract(const Duration(days: 1)),
        ) ??
        previousPaycheck.subtract(const Duration(days: 14));

    final periods = <OutlookPeriod>[
      _buildBiweeklyPeriod(
        label: 'Previous',
        from: previousPreviousPaycheck,
        to: previousPaycheck.subtract(const Duration(days: 1)),
      ),
      _buildBiweeklyPeriod(
        label: 'Current',
        from: previousPaycheck,
        to: paycheck1.subtract(const Duration(days: 1)),
        includeCarryoverUnpaidBeforeFrom: true,
      ),
    ];

    var nextFrom = paycheck1;
    for (var i = 1; i <= 6; i++) {
      final nextPaycheck =
          _getNextPaycheckAfter(nextFrom) ??
          nextFrom.add(const Duration(days: 14));
      periods.add(
        _buildBiweeklyPeriod(
          label: 'Next $i',
          from: nextFrom,
          to: nextPaycheck.subtract(const Duration(days: 1)),
        ),
      );
      nextFrom = nextPaycheck;
    }

    return periods;
  }

  /// Three calendar-month outlook periods: previous, current and next.
  List<OutlookPeriod> get monthlyOutlook {
    final now = _now;
    final previousYear = now.month == 1 ? now.year - 1 : now.year;
    final previousMonth = now.month == 1 ? 12 : now.month - 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    return [
      _buildMonthOutlook(
        label: 'Previous Month',
        year: previousYear,
        month: previousMonth,
      ),
      _buildMonthOutlook(
        label: 'Current Month',
        year: now.year,
        month: now.month,
        includeAccountBalanceBase: true,
      ),
      _buildMonthOutlook(label: 'Next Month', year: nextYear, month: nextMonth),
    ];
  }

  OutlookPeriod _buildBiweeklyPeriod({
    required String label,
    required DateTime from,
    required DateTime to,
    bool includeCarryoverUnpaidBeforeFrom = false,
  }) {
    final now = DateTime(_now.year, _now.month, _now.day);
    final isCurrentWindow =
        !now.isBefore(DateTime(from.year, from.month, from.day)) &&
        !now.isAfter(DateTime(to.year, to.month, to.day));

    final dayStartFrom = DateTime(from.year, from.month, from.day);
    final projections = _txRepo.projectionsForRange(from: from, to: to);
    final carryover = includeCarryoverUnpaidBeforeFrom
        ? _buildCarryoverUnpaid(before: dayStartFrom)
        : <({Transaction transaction, DateTime date})>[];

    final combined = [...carryover, ...projections];

    double incomeValue = isCurrentWindow ? _accountsRepo.totalBalance : 0;
    double expenses = 0;
    final items = <OutlookItem>[];

    for (final p in combined) {
      final isPaid = _txRepo.isOccurrencePaid(p.transaction.id, p.date);
      if (p.transaction.type == TransactionType.income) {
        if (!isPaid) {
          incomeValue += p.transaction.amount;
        }
      } else if (p.transaction.type == TransactionType.expense) {
        if (!isPaid) {
          expenses += p.transaction.amount;
        }
      }

      items.add(
        OutlookItem(
          transactionId: p.transaction.id,
          title: p.transaction.title,
          amount: p.transaction.amount,
          type: p.transaction.type,
          date: p.date,
          isPaid: isPaid,
        ),
      );
    }

    // Sort items chronologically
    items.sort((a, b) => a.date.compareTo(b.date));

    return OutlookPeriod(
      label: label,
      from: from,
      to: to,
      income: incomeValue,
      expenses: expenses,
      items: items,
      showAccountBalanceLabel: true,
    );
  }

  List<({Transaction transaction, DateTime date})> _buildCarryoverUnpaid({
    required DateTime before,
  }) {
    final lookbackFrom = before.subtract(const Duration(days: 90));
    final lookbackTo = before.subtract(const Duration(days: 1));
    final historical = _txRepo.projectionsForRange(
      from: lookbackFrom,
      to: lookbackTo,
    );
    return historical.where((p) {
      return !_txRepo.isOccurrencePaid(p.transaction.id, p.date);
    }).toList();
  }

  /// Finds the next paycheck date by looking for the nearest future occurrence
  /// of any recurring income transaction.
  DateTime? _getNextPaycheckDate() {
    final now = _now;
    final recurringIncomes = _txRepo.all.where(
      (t) =>
          t.isRecurring &&
          t.type == TransactionType.income &&
          t.recurrenceFrequency != RecurrenceFrequency.none,
    );

    if (recurringIncomes.isEmpty) return null;

    DateTime? earliest;
    for (final t in recurringIncomes) {
      final next = t.nextOccurrenceAfter(now.subtract(const Duration(days: 1)));
      if (next != null && (earliest == null || next.isBefore(earliest))) {
        earliest = next;
      }
    }
    return earliest;
  }

  /// Finds the next paycheck date after the given date.
  DateTime? _getNextPaycheckAfter(DateTime date) {
    final recurringIncomes = _txRepo.all.where(
      (t) =>
          t.isRecurring &&
          t.type == TransactionType.income &&
          t.recurrenceFrequency != RecurrenceFrequency.none,
    );

    if (recurringIncomes.isEmpty) return null;

    DateTime? earliest;
    for (final t in recurringIncomes) {
      final next = t.nextOccurrenceAfter(date);
      if (next != null && (earliest == null || next.isBefore(earliest))) {
        earliest = next;
      }
    }
    return earliest;
  }

  DateTime? _getPreviousPaycheckDate(DateTime date) {
    final recurringIncomes = _txRepo.all.where(
      (t) =>
          t.isRecurring &&
          t.type == TransactionType.income &&
          t.recurrenceFrequency != RecurrenceFrequency.none,
    );

    if (recurringIncomes.isEmpty) return null;

    DateTime? latest;
    for (final t in recurringIncomes) {
      final previous = _lastOccurrenceOnOrBefore(t, date);
      if (previous != null && (latest == null || previous.isAfter(latest))) {
        latest = previous;
      }
    }
    return latest;
  }

  DateTime? _lastOccurrenceOnOrBefore(Transaction t, DateTime date) {
    if (!t.isRecurring || t.recurrenceFrequency == RecurrenceFrequency.none) {
      return null;
    }
    if (t.date.isAfter(date)) {
      return null;
    }

    var current = DateTime(t.date.year, t.date.month, t.date.day);
    final target = DateTime(date.year, date.month, date.day);
    var safety = 0;
    const maxIterations = 5000;

    while (safety++ < maxIterations) {
      final next = _advanceByFrequency(current, t.recurrenceFrequency);
      if (next.isAfter(target)) {
        return current;
      }
      current = next;
    }

    return current;
  }

  DateTime _advanceByFrequency(DateTime date, RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurrenceFrequency.biweekly:
        return date.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case RecurrenceFrequency.quarterly:
        return DateTime(date.year, date.month + 3, date.day);
      case RecurrenceFrequency.annually:
        return DateTime(date.year + 1, date.month, date.day);
      case RecurrenceFrequency.none:
        return date;
    }
  }

  OutlookPeriod _buildMonthOutlook({
    required String label,
    required int year,
    required int month,
    bool includeAccountBalanceBase = false,
  }) {
    final txns = _txRepo.forMonthIncludingRecurring(year, month);
    double income = includeAccountBalanceBase ? _accountsRepo.totalBalance : 0;
    double expenses = 0;
    final items = <OutlookItem>[];
    for (final t in txns) {
      final isPaid = _txRepo.isOccurrencePaid(t.id, t.date);
      if (t.type == TransactionType.income) {
        if (!isPaid) {
          income += t.amount;
        }
      } else if (t.type == TransactionType.expense) {
        if (!isPaid) {
          expenses += t.amount;
        }
      }
      items.add(
        OutlookItem(
          transactionId: t.id,
          title: t.title,
          amount: t.amount,
          type: t.type,
          date: t.date,
          isPaid: isPaid,
        ),
      );
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return OutlookPeriod(
      label: label,
      from: DateTime(year, month, 1),
      income: income,
      expenses: expenses,
      items: items,
      showAccountBalanceLabel: includeAccountBalanceBase,
    );
  }

  Future<void> toggleOutlookItemPaid(OutlookItem item) async {
    final wasPaid = _txRepo.isOccurrencePaid(item.transactionId, item.date);
    await _txRepo.toggleOccurrencePaid(item.transactionId, item.date);
    final nowPaid = _txRepo.isOccurrencePaid(item.transactionId, item.date);
    final transaction = _txRepo.findById(item.transactionId);
    if (transaction != null) {
      await _syncGoalFromPaidToggle(
        transaction: transaction,
        occurrenceDate: item.date,
        wasPaid: wasPaid,
        nowPaid: nowPaid,
      );
    }
    notifyListeners();
  }

  bool isOccurrencePaid(String transactionId, DateTime date) {
    return _txRepo.isOccurrencePaid(transactionId, date);
  }

  Future<void> toggleOccurrencePaid(String transactionId, DateTime date) async {
    final wasPaid = _txRepo.isOccurrencePaid(transactionId, date);
    await _txRepo.toggleOccurrencePaid(transactionId, date);
    final nowPaid = _txRepo.isOccurrencePaid(transactionId, date);
    final transaction = _txRepo.findById(transactionId);
    if (transaction != null) {
      await _syncGoalFromPaidToggle(
        transaction: transaction,
        occurrenceDate: date,
        wasPaid: wasPaid,
        nowPaid: nowPaid,
      );
    }
    notifyListeners();
  }

  Future<void> _syncGoalFromPaidToggle({
    required Transaction transaction,
    required DateTime occurrenceDate,
    required bool wasPaid,
    required bool nowPaid,
  }) async {
    if (wasPaid == nowPaid) return;
    final goalId = transaction.goalId;
    if (goalId == null) return;

    final goal = _goalsRepo.findById(goalId);
    if (goal == null) return;

    final delta = nowPaid ? transaction.amount : -transaction.amount;
    final newAmount = (goal.currentAmount + delta).clamp(0.0, goal.targetAmount);
    await _goalsRepo.update(
      goal.copyWith(currentAmount: newAmount, updatedAt: DateTime.now()),
    );

    final milestones = _milestonesRepo.milestonesForGoal(goalId);
    for (final milestone in milestones) {
      if (!milestone.isCompleted && newAmount >= milestone.targetAmount) {
        await _milestonesRepo.update(
          milestone.copyWith(completedAt: occurrenceDate),
        );
      } else if (milestone.isCompleted && newAmount < milestone.targetAmount) {
        await _milestonesRepo.update(milestone.copyWith(clearCompletedAt: true));
      }
    }
  }

  void refresh() => notifyListeners();

  void _onRepositoryChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _txRepo.removeListener(_onRepositoryChanged);
    _accountsRepo.removeListener(_onRepositoryChanged);
    _debtRepo.removeListener(_onRepositoryChanged);
    _goalsRepo.removeListener(_onRepositoryChanged);
    _milestonesRepo.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
