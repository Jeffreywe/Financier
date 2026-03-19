import 'package:financier/data/repositories/categories_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/domain/models/budget_category.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class TransactionsViewModel extends ChangeNotifier {
  final TransactionsRepository _txRepo;
  final CategoriesRepository _catRepo;
  final _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;
  TransactionType? _filterType;

  TransactionsViewModel(this._txRepo, this._catRepo);

  bool get isLoading => _isLoading;
  String? get error => _error;
  TransactionType? get filterType => _filterType;

  List<BudgetCategory> get categories => _catRepo.all;

  List<Transaction> get filtered {
    if (_filterType == null) return _txRepo.all;
    return _txRepo.all.where((t) => t.type == _filterType).toList();
  }

  /// Groups filtered transactions by date (yyyy-MM-dd).
  Map<DateTime, List<Transaction>> get groupedByDate {
    final groups = <DateTime, List<Transaction>>{};
    for (final t in filtered) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  /// Returns a sorted list of date keys (newest first).
  List<DateTime> get sortedDateKeys {
    final keys = groupedByDate.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  List<({Transaction transaction, DateTime nextDate})> upcomingBills({
    int days = 7,
  }) {
    final now = DateTime.now();
    final to = now.add(Duration(days: days));
    return _txRepo
        .upcomingRecurring(from: now, to: to)
        .where((r) => r.transaction.type == TransactionType.expense)
        .toList();
  }

  Transaction? findById(String id) {
    try {
      return _txRepo.all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Transaction> transactionsForDebt(String debtId) {
    final linked = _txRepo.all.where((t) => t.debtId == debtId).toList();
    linked.sort((a, b) => b.date.compareTo(a.date));
    return linked;
  }

  void setFilter(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required DateTime date,
    bool isRecurring = false,
    RecurrenceFrequency recurrenceFrequency = RecurrenceFrequency.none,
    String? accountId,
    String? note,
  }) async {
    _setLoading(true);
    try {
      await _txRepo.add(
        Transaction(
          id: _uuid.v4(),
          title: title,
          amount: amount,
          type: type,
          categoryId: categoryId,
          date: date,
          isRecurring: isRecurring,
          recurrenceFrequency: recurrenceFrequency,
          accountId: accountId,
          note: note,
        ),
      );
    } catch (e) {
      _error = 'Failed to add transaction: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      await _txRepo.update(transaction);
    } catch (e) {
      _error = 'Failed to update transaction: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _setLoading(true);
    try {
      await _txRepo.delete(id);
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
