import 'package:file_picker/file_picker.dart';
import 'package:financier/data/services/data_port_service.dart';
import 'package:flutter/foundation.dart';

class DataPortViewModel extends ChangeNotifier {
  final DataPortService _service;

  bool _isBusy = false;
  String? _error;
  String? _info;
  String? _exportDirectory;
  List<ExportHistoryEntry> _exportHistory = const [];

  DataPortViewModel(this._service) {
    _exportDirectory = _service.savedExportDirectory;
    _exportHistory = _service.exportHistory;
  }

  bool get isBusy => _isBusy;
  String? get error => _error;
  String? get info => _info;
  String? get exportDirectory => _exportDirectory;
  List<ExportHistoryEntry> get exportHistory =>
      List.unmodifiable(_exportHistory);

  Future<void> initializeDirectory() async {
    if (_exportDirectory != null && _exportDirectory!.isNotEmpty) return;
    _setBusy(true);
    try {
      _exportDirectory = await _service.ensureExportDirectory();
      _info = 'Export folder ready.';
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize export folder: $e';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> chooseExportDirectory() async {
    _setBusy(true);
    try {
      final selected = await _service.pickAndSaveExportDirectory();
      if (selected != null) {
        _exportDirectory = selected;
        _info = 'Export folder set to: $selected';
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to choose export folder: $e';
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> exportData() async {
    _setBusy(true);
    try {
      final path = await _service.exportCoreDataToXlsx();
      _exportDirectory = _service.savedExportDirectory;
      _exportHistory = _service.exportHistory;
      _info = 'Export complete: $path';
      _error = null;
      return path;
    } catch (e) {
      _error = 'Export failed: $e';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<ImportResult?> importData({bool replaceExisting = true}) async {
    _setBusy(true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        dialogTitle: 'Pick Financier XLSX file',
      );

      if (picked == null ||
          picked.files.isEmpty ||
          picked.files.first.path == null) {
        _info = 'Import cancelled.';
        _error = null;
        return null;
      }

      final result = await _service.importCoreDataFromXlsx(
        filePath: picked.files.first.path!,
        replaceExisting: replaceExisting,
      );

      _exportHistory = _service.exportHistory;

      _info =
          'Import complete: '
          '${result.accounts} accounts, '
          '${result.transactions} transactions, '
          '${result.debts} debts, '
          '${result.categories} categories.';
      _error = null;
      return result;
    } catch (e) {
      _error = 'Import failed: $e';
      return null;
    } finally {
      _setBusy(false);
    }
  }

  void clearMessages() {
    _error = null;
    _info = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
