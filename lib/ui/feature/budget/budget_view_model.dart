import 'package:financier/data/repositories/categories_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/domain/models/budget_category.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:flutter/foundation.dart';

class BucketSummary {
  final BudgetBucket bucket;
  final double target; // derived from income %
  final double actual;
  final List<CategorySummary> categories;

  const BucketSummary({
    required this.bucket,
    required this.target,
    required this.actual,
    required this.categories,
  });

  double get remaining => target - actual;
  double get percentUsed => target <= 0 ? 0 : (actual / target).clamp(0.0, 1.0);

  String get label {
    switch (bucket) {
      case BudgetBucket.needs:
        return 'Needs (50%)';
      case BudgetBucket.wants:
        return 'Wants (30%)';
      case BudgetBucket.savings:
        return 'Savings (20%)';
    }
  }
}

class CategorySummary {
  final String categoryId;
  final String categoryName;
  final BudgetBucket bucket;
  final double actual;

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.bucket,
    required this.actual,
  });
}

class BudgetViewModel extends ChangeNotifier {
  final TransactionsRepository _txRepo;
  final CategoriesRepository _catRepo;

  DateTime _selectedMonth;

  BudgetViewModel(this._txRepo, this._catRepo)
    : _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month) {
    _txRepo.addListener(_onRepositoryChanged);
    _catRepo.addListener(_onRepositoryChanged);
  }

  DateTime get selectedMonth => _selectedMonth;

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  List<Transaction> get _monthTransactions => _txRepo
      .forMonthIncludingRecurring(_selectedMonth.year, _selectedMonth.month);

  double get monthlyIncome => _monthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get monthlyExpenses => _monthTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get leftToBudget => monthlyIncome - monthlyExpenses;

  // 50/30/20 targets based on income
  double get needsTarget => monthlyIncome * 0.50;
  double get wantsTarget => monthlyIncome * 0.30;
  double get savingsTarget => monthlyIncome * 0.20;

  List<BucketSummary> get bucketSummaries {
    final expenses = _monthTransactions.where(
      (t) => t.type == TransactionType.expense,
    );

    final categories = _catRepo.all;
    final categoriesById = {for (final c in categories) c.id: c};
    final categoriesByNormalizedName = {
      for (final c in categories) _normalizeKey(c.name): c,
    };

    // Aggregate actual spend by resolved category id.
    final Map<String, double> spendByCategory = {};
    for (final tx in expenses) {
      final resolvedCategoryId = _resolveCategoryId(
        tx.categoryId,
        categoriesById,
        categoriesByNormalizedName,
      );
      if (resolvedCategoryId == null) {
        continue;
      }
      spendByCategory[resolvedCategoryId] =
          (spendByCategory[resolvedCategoryId] ?? 0) + tx.amount;
    }

    BucketSummary buildBucket(BudgetBucket bucket, double target) {
      final catList = _catRepo.forBucket(bucket);
      final catSummaries = catList
          .map((cat) {
            return CategorySummary(
              categoryId: cat.id,
              categoryName: cat.name,
              bucket: bucket,
              actual: spendByCategory[cat.id] ?? 0.0,
            );
          })
          .where((c) => c.actual > 0)
          .toList();

      final actual = catSummaries.fold(0.0, (s, c) => s + c.actual);
      return BucketSummary(
        bucket: bucket,
        target: target,
        actual: actual,
        categories: catSummaries,
      );
    }

    return [
      buildBucket(BudgetBucket.needs, needsTarget),
      buildBucket(BudgetBucket.wants, wantsTarget),
      buildBucket(BudgetBucket.savings, savingsTarget),
    ];
  }

  String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String? _resolveCategoryId(
    String rawCategory,
    Map<String, BudgetCategory> categoriesById,
    Map<String, BudgetCategory> categoriesByNormalizedName,
  ) {
    if (categoriesById.containsKey(rawCategory)) {
      return rawCategory;
    }

    final normalized = _normalizeKey(rawCategory);
    final byName = categoriesByNormalizedName[normalized];
    if (byName != null) {
      return byName.id;
    }

    // Imported files may carry aliases instead of internal ids.
    if (normalized.contains('rent') || normalized.contains('mortgage')) {
      return categoriesById.containsKey('cat_rent') ? 'cat_rent' : null;
    }
    if (normalized.contains('debt') && normalized.contains('payment')) {
      return categoriesById.containsKey('cat_debt_payment')
          ? 'cat_debt_payment'
          : null;
    }
    if (normalized.contains('saving')) {
      return categoriesById.containsKey('cat_savings_transfer')
          ? 'cat_savings_transfer'
          : null;
    }

    return null;
  }

  void refresh() {
    notifyListeners();
  }

  void _onRepositoryChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _txRepo.removeListener(_onRepositoryChanged);
    _catRepo.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
