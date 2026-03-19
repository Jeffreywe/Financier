import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _accountsKey = 'accounts_v1';
  static const String _transactionsKey = 'transactions_v1';
  static const String _debtsKey = 'debts_v1';
  static const String _categoriesKey = 'budget_categories_v1';
  static const String _firstLaunchKey = 'first_launch_done';
  static const String _exportDirectoryKey = 'export_directory_v1';
  static const String _exportHistoryKey = 'export_history_v1';
  static const String _paidOccurrencesKey = 'paid_occurrences_v1';
  static const String _goalsKey = 'savings_goals_v1';
  static const String _milestonesKey = 'goal_milestones_v1';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ---------------------------------------------------------------------------
  // Generic helpers
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
  }

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> readAccounts() => _readList(_accountsKey);

  Future<void> writeAccounts(List<Map<String, dynamic>> accounts) =>
      _writeList(_accountsKey, accounts);

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> readTransactions() => _readList(_transactionsKey);

  Future<void> writeTransactions(List<Map<String, dynamic>> transactions) =>
      _writeList(_transactionsKey, transactions);

  // ---------------------------------------------------------------------------
  // Debts
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> readDebts() => _readList(_debtsKey);

  Future<void> writeDebts(List<Map<String, dynamic>> debts) =>
      _writeList(_debtsKey, debts);

  // ---------------------------------------------------------------------------
  // Budget Categories
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> readCategories() => _readList(_categoriesKey);

  Future<void> writeCategories(List<Map<String, dynamic>> categories) =>
      _writeList(_categoriesKey, categories);

  // ---------------------------------------------------------------------------
  // First launch
  // ---------------------------------------------------------------------------

  bool get isFirstLaunch => !(_prefs.getBool(_firstLaunchKey) ?? false);

  Future<void> markLaunched() => _prefs.setBool(_firstLaunchKey, true);

  // ---------------------------------------------------------------------------
  // Data port / import-export settings
  // ---------------------------------------------------------------------------

  String? readExportDirectory() => _prefs.getString(_exportDirectoryKey);

  Future<void> writeExportDirectory(String path) =>
      _prefs.setString(_exportDirectoryKey, path);

  List<Map<String, dynamic>> readExportHistory() =>
      _readList(_exportHistoryKey);

  Future<void> writeExportHistory(List<Map<String, dynamic>> history) =>
      _writeList(_exportHistoryKey, history);

  // ---------------------------------------------------------------------------
  // Paid occurrence states
  // ---------------------------------------------------------------------------

  Map<String, bool> readPaidOccurrences() {
    final raw = _prefs.getString(_paidOccurrencesKey);
    if (raw == null) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};

    return decoded.map((key, value) => MapEntry(key.toString(), value == true));
  }

  Future<void> writePaidOccurrences(Map<String, bool> paidOccurrences) async {
    await _prefs.setString(_paidOccurrencesKey, jsonEncode(paidOccurrences));
  }

  // ---------------------------------------------------------------------------
  // Savings Goals
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> readGoals() => _readList(_goalsKey);

  Future<void> writeGoals(List<Map<String, dynamic>> goals) =>
      _writeList(_goalsKey, goals);

  // ---------------------------------------------------------------------------
  // Goal Milestones
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> readMilestones() => _readList(_milestonesKey);

  Future<void> writeMilestones(List<Map<String, dynamic>> milestones) =>
      _writeList(_milestonesKey, milestones);
}
