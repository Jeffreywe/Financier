import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:financier/data/repositories/accounts_repository.dart';
import 'package:financier/data/repositories/categories_repository.dart';
import 'package:financier/data/repositories/debt_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/account.dart';
import 'package:financier/domain/models/budget_category.dart';
import 'package:financier/domain/models/debt.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImportResult {
  final int accounts;
  final int transactions;
  final int debts;
  final int categories;

  const ImportResult({
    required this.accounts,
    required this.transactions,
    required this.debts,
    required this.categories,
  });
}

class ExportHistoryEntry {
  final String path;
  final DateTime exportedAt;

  const ExportHistoryEntry({required this.path, required this.exportedAt});

  Map<String, dynamic> toJson() => {
    'path': path,
    'exportedAt': exportedAt.toIso8601String(),
  };

  factory ExportHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExportHistoryEntry(
      path: json['path'] as String? ?? '',
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class DataPortService {
  final LocalStorageService _storage;
  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;
  final DebtRepository _debtRepository;
  final CategoriesRepository _categoriesRepository;

  DataPortService(
    this._storage,
    this._accountsRepository,
    this._transactionsRepository,
    this._debtRepository,
    this._categoriesRepository,
  );

  String? get savedExportDirectory => _storage.readExportDirectory();

  List<ExportHistoryEntry> get exportHistory {
    final raw = _storage.readExportHistory();
    return raw.map(ExportHistoryEntry.fromJson).toList()
      ..sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
  }

  Future<String> ensureExportDirectory() async {
    final saved = _storage.readExportDirectory();
    if (saved != null && saved.isNotEmpty) {
      final directory = Directory(saved);
      if (await directory.exists()) {
        return saved;
      }
    }

    final candidates = <String>[
      '/storage/emulated/0/Documents/Financier',
      '/storage/emulated/0/Download/Financier',
    ];

    for (final candidate in candidates) {
      try {
        final dir = Directory(candidate);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        await _storage.writeExportDirectory(candidate);
        return candidate;
      } catch (_) {
        // try next candidate
      }
    }

    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      try {
        final externalFinancier = Directory(
          p.join(externalDir.path, 'Financier'),
        );
        if (!await externalFinancier.exists()) {
          await externalFinancier.create(recursive: true);
        }
        await _storage.writeExportDirectory(externalFinancier.path);
        return externalFinancier.path;
      } catch (_) {
        // continue to app-docs fallback
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fallback = Directory(p.join(appDir.path, 'Financier'));
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    await _storage.writeExportDirectory(fallback.path);
    return fallback.path;
  }

  Future<String?> pickAndSaveExportDirectory() async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose parent folder for Financier exports',
    );
    if (picked == null) return null;

    final normalized = picked.replaceAll('\\', '/');
    final alreadyFinancier = normalized.toLowerCase().endsWith('/financier');
    final financierFolder = alreadyFinancier
        ? Directory(picked)
        : Directory(p.join(picked, 'Financier'));
    if (!await financierFolder.exists()) {
      await financierFolder.create(recursive: true);
    }

    await _storage.writeExportDirectory(financierFolder.path);
    return financierFolder.path;
  }

  Future<String> exportCoreDataToXlsx() async {
    final exportDirectory = await ensureExportDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final filename = 'financier_export_$timestamp.xlsx';
    final filePath = p.join(exportDirectory, filename);

    final excel = Excel.createExcel();
    _writeAccountsSheet(excel);
    _writeTransactionsSheet(excel);
    _writeDebtsSheet(excel);
    _writeCategoriesSheet(excel);
    _writeMetaSheet(excel);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate XLSX bytes.');
    }

    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      await _recordExportHistory(file.path);
      return file.path;
    } on FileSystemException {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Financier Export',
        fileName: filename,
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );

      if (savedPath == null || savedPath.isEmpty) {
        throw Exception(
          'Unable to write to the selected folder. '
          'Choose a writable location in Google Files and try again.',
        );
      }

      await _recordExportHistory(savedPath);
      return savedPath;
    }
  }

  Future<void> _recordExportHistory(String path) async {
    final updated = <ExportHistoryEntry>[
      ExportHistoryEntry(path: path, exportedAt: DateTime.now()),
      ...exportHistory.where((e) => e.path != path),
    ];
    final capped = updated.take(20).map((e) => e.toJson()).toList();
    await _storage.writeExportHistory(capped);
  }

  Future<ImportResult> importCoreDataFromXlsx({
    required String filePath,
    bool replaceExisting = true,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected file does not exist.');
    }

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final accounts = _readAccountsSheet(excel);
    final transactions = _readTransactionsSheet(excel);
    final debts = _readDebtsSheet(excel);
    final categories = _readCategoriesSheet(excel);

    if (!replaceExisting) {
      accounts.addAll(_accountsRepository.all);
      transactions.addAll(_transactionsRepository.all);
      debts.addAll(_debtRepository.all);
      categories.addAll(_categoriesRepository.all);
    }

    await _accountsRepository.replaceAll(_dedupeById(accounts));
    await _transactionsRepository.replaceAll(_dedupeById(transactions));
    await _debtRepository.replaceAll(_dedupeById(debts));
    if (categories.isNotEmpty) {
      await _categoriesRepository.replaceAll(_dedupeById(categories));
    }

    return ImportResult(
      accounts: accounts.length,
      transactions: transactions.length,
      debts: debts.length,
      categories: categories.length,
    );
  }

  void _writeAccountsSheet(Excel excel) {
    final sheet = excel['Accounts'];
    sheet.appendRow(_row(['id', 'name', 'type', 'balance', 'note']));

    for (final account in _accountsRepository.all) {
      sheet.appendRow(
        _row([
          account.id,
          account.name,
          account.type.name,
          account.balance,
          account.note ?? '',
        ]),
      );
    }
  }

  void _writeTransactionsSheet(Excel excel) {
    final sheet = excel['Transactions'];
    sheet.appendRow(
      _row([
        'id',
        'title',
        'amount',
        'type',
        'categoryId',
        'dateIso',
        'isRecurring',
        'recurrenceFrequency',
        'accountId',
        'note',
      ]),
    );

    for (final transaction in _transactionsRepository.all) {
      sheet.appendRow(
        _row([
          transaction.id,
          transaction.title,
          transaction.amount,
          transaction.type.name,
          transaction.categoryId,
          transaction.date.toIso8601String(),
          transaction.isRecurring,
          transaction.recurrenceFrequency.name,
          transaction.accountId ?? '',
          transaction.note ?? '',
        ]),
      );
    }
  }

  void _writeDebtsSheet(Excel excel) {
    final sheet = excel['Debts'];
    sheet.appendRow(
      _row([
        'id',
        'name',
        'debtType',
        'balance',
        'interestRate',
        'minimumPayment',
        'dueDay',
        'note',
      ]),
    );

    for (final debt in _debtRepository.all) {
      sheet.appendRow(
        _row([
          debt.id,
          debt.name,
          debt.debtType.name,
          debt.balance,
          debt.interestRate ?? '',
          debt.minimumPayment ?? '',
          debt.dueDay ?? '',
          debt.note ?? '',
        ]),
      );
    }
  }

  void _writeCategoriesSheet(Excel excel) {
    final sheet = excel['Categories'];
    sheet.appendRow(_row(['id', 'name', 'bucket', 'isDefault']));

    for (final category in _categoriesRepository.all) {
      sheet.appendRow(
        _row([
          category.id,
          category.name,
          category.bucket.name,
          category.isDefault,
        ]),
      );
    }
  }

  void _writeMetaSheet(Excel excel) {
    final sheet = excel['Meta'];
    sheet.appendRow(_row(['key', 'value']));
    sheet.appendRow(_row(['app', 'Financier']));
    sheet.appendRow(_row(['version', '1']));
    sheet.appendRow(_row(['exportedAt', DateTime.now().toIso8601String()]));
  }

  List<Account> _readAccountsSheet(Excel excel) {
    final table = excel.tables['Accounts'];
    if (table == null || table.rows.length <= 1) return <Account>[];

    final rows = table.rows.skip(1);
    final result = <Account>[];

    for (final row in rows) {
      final id = _cellString(row, 0);
      final name = _cellString(row, 1);
      final typeRaw = _cellString(row, 2);
      final balanceRaw = _cellString(row, 3);
      final note = _cellString(row, 4);

      if (id.isEmpty || name.isEmpty) continue;
      final type = _accountTypeFrom(typeRaw);
      final balance = double.tryParse(balanceRaw) ?? 0.0;

      result.add(
        Account(
          id: id,
          name: name,
          type: type,
          balance: balance,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    return result;
  }

  List<Transaction> _readTransactionsSheet(Excel excel) {
    final table = excel.tables['Transactions'];
    if (table == null || table.rows.length <= 1) return <Transaction>[];

    final rows = table.rows.skip(1);
    final result = <Transaction>[];

    for (final row in rows) {
      final id = _cellString(row, 0);
      final title = _cellString(row, 1);
      final amountRaw = _cellString(row, 2);
      final typeRaw = _cellString(row, 3);
      final categoryId = _cellString(row, 4);
      final dateRaw = _cellString(row, 5);
      final recurringRaw = _cellString(row, 6);
      final frequencyRaw = _cellString(row, 7);
      final accountId = _cellString(row, 8);
      final note = _cellString(row, 9);

      if (id.isEmpty ||
          title.isEmpty ||
          categoryId.isEmpty ||
          dateRaw.isEmpty) {
        continue;
      }

      final amount = double.tryParse(amountRaw) ?? 0.0;
      final date = DateTime.tryParse(dateRaw);
      if (date == null) continue;

      final type = _transactionTypeFrom(typeRaw);
      final isRecurring = recurringRaw.toLowerCase() == 'true';
      final frequency = _frequencyFrom(frequencyRaw);

      result.add(
        Transaction(
          id: id,
          title: title,
          amount: amount,
          type: type,
          categoryId: categoryId,
          date: date,
          isRecurring: isRecurring,
          recurrenceFrequency: frequency,
          accountId: accountId.isEmpty ? null : accountId,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    return result;
  }

  List<Debt> _readDebtsSheet(Excel excel) {
    final table = excel.tables['Debts'];
    if (table == null || table.rows.length <= 1) return <Debt>[];

    final rows = table.rows.skip(1);
    final result = <Debt>[];

    for (final row in rows) {
      final id = _cellString(row, 0);
      final name = _cellString(row, 1);
      final debtTypeRaw = _cellString(row, 2);
      final balanceRaw = _cellString(row, 3);
      final interestRateRaw = _cellString(row, 4);
      final minimumPaymentRaw = _cellString(row, 5);
      final dueDayRaw = _cellString(row, 6);
      final note = _cellString(row, 7);

      if (id.isEmpty || name.isEmpty) continue;

      result.add(
        Debt(
          id: id,
          name: name,
          debtType: _debtTypeFrom(debtTypeRaw),
          balance: double.tryParse(balanceRaw) ?? 0.0,
          interestRate: _nullableDouble(interestRateRaw),
          minimumPayment: _nullableDouble(minimumPaymentRaw),
          dueDay: int.tryParse(dueDayRaw),
          note: note.isEmpty ? null : note,
        ),
      );
    }

    return result;
  }

  List<BudgetCategory> _readCategoriesSheet(Excel excel) {
    final table = excel.tables['Categories'];
    if (table == null || table.rows.length <= 1) return <BudgetCategory>[];

    final rows = table.rows.skip(1);
    final result = <BudgetCategory>[];

    for (final row in rows) {
      final id = _cellString(row, 0);
      final name = _cellString(row, 1);
      final bucketRaw = _cellString(row, 2);
      final isDefaultRaw = _cellString(row, 3);

      if (id.isEmpty || name.isEmpty || bucketRaw.isEmpty) continue;

      result.add(
        BudgetCategory(
          id: id,
          name: name,
          bucket: _bucketFrom(bucketRaw),
          isDefault: isDefaultRaw.toLowerCase() == 'true',
        ),
      );
    }

    return result;
  }

  List<T> _dedupeById<T>(List<T> items) {
    final byId = <String, T>{};
    for (final item in items) {
      final id = (item as dynamic).id as String;
      byId[id] = item;
    }
    return byId.values.toList();
  }

  List<CellValue?> _row(List<Object?> values) {
    return values.map(_toCellValue).toList();
  }

  CellValue? _toCellValue(Object? value) {
    if (value == null) return null;
    if (value is bool) return BoolCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue(value.toString());
  }

  String _cellString(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final value = row[index]?.value;
    return value?.toString().trim() ?? '';
  }

  double? _nullableDouble(String raw) {
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  AccountType _accountTypeFrom(String raw) {
    switch (raw) {
      case 'checking':
        return AccountType.checking;
      case 'savings':
        return AccountType.savings;
      case 'credit':
        return AccountType.credit;
      case 'cash':
        return AccountType.cash;
      default:
        return AccountType.other;
    }
  }

  TransactionType _transactionTypeFrom(String raw) {
    switch (raw) {
      case 'income':
        return TransactionType.income;
      case 'note':
        return TransactionType.note;
      default:
        return TransactionType.expense;
    }
  }

  RecurrenceFrequency _frequencyFrom(String raw) {
    switch (raw) {
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'biweekly':
        return RecurrenceFrequency.biweekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'quarterly':
        return RecurrenceFrequency.quarterly;
      case 'annually':
        return RecurrenceFrequency.annually;
      default:
        return RecurrenceFrequency.none;
    }
  }

  DebtType _debtTypeFrom(String raw) {
    switch (raw) {
      case 'creditCard':
        return DebtType.creditCard;
      case 'studentLoan':
        return DebtType.studentLoan;
      case 'carLoan':
        return DebtType.carLoan;
      case 'mortgage':
        return DebtType.mortgage;
      case 'personalLoan':
        return DebtType.personalLoan;
      case 'medicalDebt':
        return DebtType.medicalDebt;
      default:
        return DebtType.other;
    }
  }

  BudgetBucket _bucketFrom(String raw) {
    switch (raw) {
      case 'needs':
        return BudgetBucket.needs;
      case 'wants':
        return BudgetBucket.wants;
      case 'savings':
        return BudgetBucket.savings;
      default:
        return BudgetBucket.needs;
    }
  }
}
