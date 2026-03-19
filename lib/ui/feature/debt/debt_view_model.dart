import 'package:financier/data/repositories/debt_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/domain/models/debt.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DebtAmortizationRow {
  final int monthNumber;
  final DateTime month;
  final double startingBalance;
  final double payment;
  final double interest;
  final double principal;
  final double endingBalance;

  const DebtAmortizationRow({
    required this.monthNumber,
    required this.month,
    required this.startingBalance,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.endingBalance,
  });
}

class DebtViewModel extends ChangeNotifier {
  final DebtRepository _repository;
  final TransactionsRepository _transactionsRepository;
  final _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;

  DebtViewModel(this._repository, this._transactionsRepository) {
    _repository.addListener(_onRepositoryChanged);
    _transactionsRepository.addListener(_onRepositoryChanged);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Debt> get debts {
    final sorted = _repository.all.toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    return sorted;
  }

  double get totalBalance => _repository.totalBalance;
  double get totalMinimumPayment => _repository.totalMinimumPayment;

  Debt? findById(String id) {
    try {
      return _repository.all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addDebt({
    required String name,
    required DebtType debtType,
    required double balance,
    double? interestRate,
    double? minimumPayment,
    double? customPayment,
    int? dueDay,
    String? note,
  }) async {
    _setLoading(true);
    try {
      await _repository.add(
        Debt(
          id: _uuid.v4(),
          name: name,
          debtType: debtType,
          balance: balance,
          interestRate: interestRate,
          minimumPayment: minimumPayment,
          customPayment: customPayment,
          dueDay: dueDay,
          note: note,
        ),
      );
    } catch (e) {
      _error = 'Failed to add debt: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDebt(Debt debt) async {
    _setLoading(true);
    try {
      await _repository.update(debt);
    } catch (e) {
      _error = 'Failed to update debt: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCustomPayment(String debtId, double? customPayment) async {
    final existing = findById(debtId);
    if (existing == null) return;
    await updateDebt(
      existing.copyWith(
        customPayment: customPayment,
        clearCustomPayment: customPayment == null,
      ),
    );
  }

  Future<int> addDebtPaymentTransactions({
    required Debt debt,
    required DateTime startDate,
    bool isRecurring = true,
    RecurrenceFrequency recurrenceFrequency = RecurrenceFrequency.monthly,
  }) async {
    final minimumPayment = (debt.minimumPayment ?? 0).clamp(0, double.infinity);
    final customPayment = (debt.customPayment ?? 0).clamp(0, double.infinity);

    if (minimumPayment <= 0 && customPayment <= 0) {
      _error = 'Set a minimum or custom payment before adding a transaction.';
      notifyListeners();
      return 0;
    }

    _setLoading(true);
    var createdCount = 0;
    try {
      final effectiveFrequency = isRecurring
          ? recurrenceFrequency
          : RecurrenceFrequency.none;
      final normalizedDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      if (minimumPayment > 0) {
        await _transactionsRepository.add(
          Transaction(
            id: _uuid.v4(),
            title: '${debt.name} Minimum Payment',
            amount: minimumPayment.toDouble(),
            type: TransactionType.expense,
            categoryId: 'cat_debt_payment',
            date: normalizedDate,
            isRecurring: isRecurring,
            recurrenceFrequency: effectiveFrequency,
            debtId: debt.id,
            note: 'Minimum debt payment for ${debt.name}',
          ),
        );
        createdCount += 1;
      }

      if (customPayment > 0) {
        await _transactionsRepository.add(
          Transaction(
            id: _uuid.v4(),
            title: '${debt.name} Custom Payment',
            amount: customPayment.toDouble(),
            type: TransactionType.expense,
            categoryId: 'cat_debt_payment',
            date: normalizedDate,
            isRecurring: isRecurring,
            recurrenceFrequency: effectiveFrequency,
            debtId: debt.id,
            note: 'Custom debt payment for ${debt.name}',
          ),
        );
        createdCount += 1;
      }
    } catch (e) {
      _error = 'Failed to add debt payment transaction: $e';
    } finally {
      _setLoading(false);
    }

    return createdCount;
  }

  List<DebtAmortizationRow> amortizationForDebt({
    required String debtId,
    int maxMonths = 480,
  }) {
    final debt = findById(debtId);
    if (debt == null || debt.balance <= 0) {
      return const [];
    }

    final monthlyRate =
        ((debt.interestRate ?? 0).clamp(0, double.infinity)) / 100 / 12;
    final minimumPayment = (debt.minimumPayment ?? 0)
        .clamp(0, double.infinity)
        .toDouble();
    final customPayment = (debt.customPayment ?? 0)
        .clamp(0, double.infinity)
        .toDouble();
    final basePayment = minimumPayment + customPayment;

    if (basePayment <= 0) {
      return const [];
    }

    var balance = debt.balance;

    final rows = <DebtAmortizationRow>[];
    final monthAnchor = DateTime(DateTime.now().year, DateTime.now().month, 1);

    for (var monthNumber = 1; monthNumber <= maxMonths; monthNumber++) {
      if (balance <= _epsilon) {
        break;
      }

      final startingBalance = balance;
      final interest = startingBalance * monthlyRate;
      final due = startingBalance + interest;

      var payment = basePayment.clamp(0, due).toDouble();
      final interestOnlyPayment = interest.clamp(0, due).toDouble();
      if (payment < interestOnlyPayment) {
        payment = interestOnlyPayment;
      }

      final principal = (payment - interest).clamp(0, due).toDouble();
      final endingBalance = (due - payment)
          .clamp(0, double.infinity)
          .toDouble();

      rows.add(
        DebtAmortizationRow(
          monthNumber: monthNumber,
          month: DateTime(
            monthAnchor.year,
            monthAnchor.month + (monthNumber - 1),
          ),
          startingBalance: startingBalance,
          payment: payment,
          interest: interest,
          principal: principal,
          endingBalance: endingBalance < _epsilon ? 0 : endingBalance,
        ),
      );

      balance = endingBalance;
    }

    return rows;
  }

  Future<void> deleteDebt(String id) async {
    _setLoading(true);
    try {
      await _repository.delete(id);
    } catch (e) {
      _error = 'Failed to delete debt: $e';
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

  void _onRepositoryChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _transactionsRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}

const double _epsilon = 0.000001;
