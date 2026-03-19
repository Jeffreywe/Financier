import 'package:financier/data/repositories/accounts_repository.dart';
import 'package:financier/domain/models/account.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AccountsViewModel extends ChangeNotifier {
  final AccountsRepository _repository;
  final _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;

  AccountsViewModel(this._repository) {
    _repository.addListener(_onRepositoryChanged);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Account> get accounts => _repository.all;
  double get totalBalance => _repository.totalBalance;

  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double balance,
    String? note,
  }) async {
    _setLoading(true);
    try {
      await _repository.add(
        Account(
          id: _uuid.v4(),
          name: name,
          type: type,
          balance: balance,
          note: note,
        ),
      );
    } catch (e) {
      _error = 'Failed to add account: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAccount(Account account) async {
    _setLoading(true);
    try {
      await _repository.update(account);
    } catch (e) {
      _error = 'Failed to update account: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(String id) async {
    _setLoading(true);
    try {
      await _repository.delete(id);
    } catch (e) {
      _error = 'Failed to delete account: $e';
    } finally {
      _setLoading(false);
    }
  }

  Account? findById(String id) => _repository.findById(id);

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
    super.dispose();
  }
}
