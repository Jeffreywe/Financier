import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';

class TransactionsRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<Transaction> _cache = [];
  Map<String, bool> _paidOccurrences = {};

  TransactionsRepository(this._storage) {
    _load();
  }

  void _load() {
    _cache = _storage.readTransactions().map(Transaction.fromJson).toList();
    _cache.sort((a, b) => b.date.compareTo(a.date));
    _paidOccurrences = _storage.readPaidOccurrences();
    notifyListeners();
  }

  List<Transaction> get all => List.unmodifiable(_cache);

  Transaction? findById(String id) {
    try {
      return _cache.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  String _occurrenceKey(String transactionId, DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '$transactionId|${normalized.toIso8601String()}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isOccurrencePaid(String transactionId, DateTime date) {
    final key = _occurrenceKey(transactionId, date);
    final override = _paidOccurrences[key];
    if (override != null) return override;

    final transaction = findById(transactionId);
    if (transaction == null) return false;

    if (!transaction.isRecurring) {
      return transaction.isPaid;
    }

    if (_isSameDay(transaction.date, date)) {
      return transaction.isPaid;
    }

    return false;
  }

  Future<void> setOccurrencePaid(
    String transactionId,
    DateTime date,
    bool isPaid,
  ) async {
    final transaction = findById(transactionId);
    final isOriginalOccurrence =
        transaction != null && _isSameDay(transaction.date, date);
    final shouldPersistOnTransaction =
        transaction != null && (!transaction.isRecurring || isOriginalOccurrence);

    final key = _occurrenceKey(transactionId, date);

    if (shouldPersistOnTransaction) {
      _paidOccurrences.remove(key);
      await _storage.writePaidOccurrences(_paidOccurrences);
      await update(transaction.copyWith(isPaid: isPaid));
      notifyListeners();
      return;
    }

    if (isPaid) {
      _paidOccurrences[key] = true;
    } else {
      _paidOccurrences.remove(key);
    }
    await _storage.writePaidOccurrences(_paidOccurrences);
    notifyListeners();
  }

  Future<void> toggleOccurrencePaid(String transactionId, DateTime date) async {
    final current = isOccurrencePaid(transactionId, date);
    await setOccurrencePaid(transactionId, date, !current);
  }

  List<Transaction> forMonth(int year, int month) => _cache
      .where((t) => t.date.year == year && t.date.month == month)
      .toList();

  List<Transaction> get incomeOnly =>
      _cache.where((t) => t.type == TransactionType.income).toList();

  List<Transaction> get expensesOnly =>
      _cache.where((t) => t.type == TransactionType.expense).toList();

  /// Returns recurring transactions whose next occurrence falls within
  /// [from] (inclusive) to [to] (inclusive).
  List<({Transaction transaction, DateTime nextDate})> upcomingRecurring({
    required DateTime from,
    required DateTime to,
  }) {
    final results = <({Transaction transaction, DateTime nextDate})>[];
    for (final t in _cache.where((t) => t.isRecurring)) {
      final next = t.nextOccurrenceAfter(
        from.subtract(const Duration(days: 1)),
      );
      if (next != null && !next.isAfter(to)) {
        results.add((transaction: t, nextDate: next));
      }
    }
    results.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return results;
  }

  /// Returns actual transactions for [year]/[month] PLUS projected recurring
  /// occurrences that fall in that month (excluding the occurrence on the
  /// original transaction date, which is already in the actual list).
  List<Transaction> forMonthIncludingRecurring(int year, int month) {
    final actual = forMonth(year, month);
    final monthStart = DateTime(year, month, 1);
    // Last millisecond of the month so that any time-of-day is covered.
    final monthEnd = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    final projected = <Transaction>[];
    for (final t in _cache) {
      if (!t.isRecurring || t.recurrenceFrequency == RecurrenceFrequency.none) {
        continue;
      }
      final occurrences = _occurrencesInRange(t, monthStart, monthEnd);
      for (final occ in occurrences) {
        // Skip the occurrence that matches the original transaction date so we
        // don't duplicate entries that are already in [actual].
        final isOriginal =
            occ.year == t.date.year &&
            occ.month == t.date.month &&
            occ.day == t.date.day;
        if (!isOriginal) {
          projected.add(t.copyWith(date: occ));
        }
      }
    }
    return [...actual, ...projected];
  }

  /// Returns all transactions (non-recurring actuals + recurring projections)
  /// whose date falls within [from]..[to] (both inclusive at day level).
  List<({Transaction transaction, DateTime date})> projectionsForRange({
    required DateTime from,
    required DateTime to,
  }) {
    final results = <({Transaction transaction, DateTime date})>[];

    for (final t in _cache) {
      if (!t.isRecurring || t.recurrenceFrequency == RecurrenceFrequency.none) {
        // Non-recurring: include if its date is within the window.
        if (!t.date.isBefore(from) && !t.date.isAfter(to)) {
          results.add((transaction: t, date: t.date));
        }
      } else {
        // Recurring: project all occurrences within the window.
        final occurrences = _occurrencesInRange(t, from, to);
        for (final occ in occurrences) {
          results.add((transaction: t, date: occ));
        }
      }
    }

    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  /// Generates all dates (at the granularity of the original transaction's
  /// time) that fall within [from]..[to] for a recurring [transaction].
  List<DateTime> _occurrencesInRange(
    Transaction t,
    DateTime from,
    DateTime to,
  ) {
    if (!t.isRecurring || t.recurrenceFrequency == RecurrenceFrequency.none) {
      return [];
    }

    final results = <DateTime>[];
    DateTime current = t.date;
    int safety = 0;
    const maxIterations = 5000;

    // Fast-forward to the first occurrence on or after [from].
    while (current.isBefore(from) && safety++ < maxIterations) {
      current = _advanceByFrequency(current, t.recurrenceFrequency);
    }

    // Collect all occurrences up to and including [to].
    while (!current.isAfter(to) && safety++ < maxIterations) {
      results.add(current);
      current = _advanceByFrequency(current, t.recurrenceFrequency);
    }

    return results;
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

  Future<void> add(Transaction transaction) async {
    _cache.add(transaction);
    _cache.sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
  }

  Future<void> update(Transaction transaction) async {
    final idx = _cache.indexWhere((t) => t.id == transaction.id);
    if (idx == -1) return;
    _cache[idx] = transaction;
    _cache.sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((t) => t.id == id);
    _paidOccurrences.removeWhere((key, _) => key.startsWith('$id|'));
    await _storage.writePaidOccurrences(_paidOccurrences);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteForGoal(String goalId) async {
    final removedIds = _cache
        .where((t) => t.goalId == goalId)
        .map((t) => t.id)
        .toSet();

    if (removedIds.isEmpty) return;

    _cache.removeWhere((t) => t.goalId == goalId);
    _paidOccurrences.removeWhere((key, _) {
      final txId = key.split('|').first;
      return removedIds.contains(txId);
    });

    await _storage.writePaidOccurrences(_paidOccurrences);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<Transaction> transactions) async {
    _cache = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final validIds = _cache.map((t) => t.id).toSet();
    _paidOccurrences.removeWhere((key, _) {
      final txId = key.split('|').first;
      return !validIds.contains(txId);
    });
    await _storage.writePaidOccurrences(_paidOccurrences);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _storage.writeTransactions(_cache.map((t) => t.toJson()).toList());
}
