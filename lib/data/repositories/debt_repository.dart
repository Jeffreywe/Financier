import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/debt.dart';
import 'package:flutter/foundation.dart';

class DebtRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<Debt> _cache = [];

  DebtRepository(this._storage) {
    _load();
  }

  void _load() {
    _cache = _storage.readDebts().map(Debt.fromJson).toList();
    notifyListeners();
  }

  List<Debt> get all => List.unmodifiable(_cache);

  double get totalBalance => _cache.fold(0.0, (sum, d) => sum + d.balance);

  double get totalMinimumPayment =>
      _cache.fold(0.0, (sum, d) => sum + (d.minimumPayment ?? 0.0));

  Future<void> add(Debt debt) async {
    _cache.add(debt);
    await _persist();
    notifyListeners();
  }

  Future<void> update(Debt debt) async {
    final idx = _cache.indexWhere((d) => d.id == debt.id);
    if (idx == -1) return;
    _cache[idx] = debt;
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((d) => d.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<Debt> debts) async {
    _cache = List<Debt>.from(debts);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _storage.writeDebts(_cache.map((d) => d.toJson()).toList());
}
