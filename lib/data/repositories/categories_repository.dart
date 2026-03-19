import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/budget_category.dart';

class CategoriesRepository {
  final LocalStorageService _storage;
  List<BudgetCategory> _cache = [];

  CategoriesRepository(this._storage) {
    _load();
  }

  void _load() {
    final stored = _storage.readCategories();
    if (stored.isEmpty) {
      _cache = List.of(defaultBudgetCategories);
    } else {
      _cache = stored.map(BudgetCategory.fromJson).toList();
    }
  }

  List<BudgetCategory> get all => List.unmodifiable(_cache);

  BudgetCategory? findById(String id) {
    try {
      return _cache.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BudgetCategory> forBucket(BudgetBucket bucket) =>
      _cache.where((c) => c.bucket == bucket).toList();

  Future<void> seedDefaults() async {
    if (_cache.isEmpty) {
      _cache = List.of(defaultBudgetCategories);
      await _persist();
    }
  }

  Future<void> add(BudgetCategory category) async {
    _cache.add(category);
    await _persist();
  }

  Future<void> update(BudgetCategory category) async {
    final idx = _cache.indexWhere((c) => c.id == category.id);
    if (idx == -1) return;
    _cache[idx] = category;
    await _persist();
  }

  Future<void> delete(String id) async {
    // Never delete defaults
    final cat = findById(id);
    if (cat == null || cat.isDefault) return;
    _cache.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> replaceAll(List<BudgetCategory> categories) async {
    _cache = List<BudgetCategory>.from(categories);
    await _persist();
  }

  Future<void> _persist() =>
      _storage.writeCategories(_cache.map((c) => c.toJson()).toList());
}
