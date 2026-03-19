import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/account.dart';
import 'package:flutter/foundation.dart';

class AccountsRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<Account> _cache = [];

  AccountsRepository(this._storage) {
    _load();
  }

  void _load() {
    _cache = _storage.readAccounts().map(Account.fromJson).toList();
    notifyListeners();
  }

  List<Account> get all => List.unmodifiable(_cache);

  double get totalBalance => _cache.fold(0.0, (sum, a) => sum + a.balance);

  Account? findById(String id) {
    try {
      return _cache.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Account account) async {
    _cache.add(account);
    await _persist();
    notifyListeners();
  }

  Future<void> update(Account account) async {
    final idx = _cache.indexWhere((a) => a.id == account.id);
    if (idx == -1) return;
    _cache[idx] = account;
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((a) => a.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<Account> accounts) async {
    _cache = List<Account>.from(accounts);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _storage.writeAccounts(_cache.map((a) => a.toJson()).toList());
}
