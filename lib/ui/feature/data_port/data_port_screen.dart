import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:financier/ui/feature/budget/budget_view_model.dart';
import 'package:financier/ui/feature/dashboard/dashboard_view_model.dart';
import 'package:financier/ui/feature/data_port/data_port_view_model.dart';
import 'package:financier/ui/feature/debt/debt_view_model.dart';
import 'package:financier/ui/feature/transactions/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DataPortScreen extends StatefulWidget {
  const DataPortScreen({super.key});

  @override
  State<DataPortScreen> createState() => _DataPortScreenState();
}

class _DataPortScreenState extends State<DataPortScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DataPortViewModel>().initializeDirectory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DataPortViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export folder',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.exportDirectory ?? 'Not set',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: vm.isBusy
                        ? null
                        : () => vm.chooseExportDirectory(),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose Folder'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tip: Choose Documents or Download in Google Files. '
                    'A Financier subfolder is created automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exports Accounts, Transactions (including income), Debts, and Categories to one XLSX file.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: vm.isBusy ? null : _onExport,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Export XLSX'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Import',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Import from XLSX and replace existing core data. Use this carefully.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.debtAccent,
                    ),
                    onPressed: vm.isBusy ? null : _onImportReplace,
                    icon: const Icon(Icons.download),
                    label: const Text('Import XLSX (Replace Data)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: vm.isBusy ? null : _onImportMerge,
                    icon: const Icon(Icons.merge_type),
                    label: const Text('Import XLSX (Merge Data)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export History',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (vm.exportHistory.isEmpty)
                    const Text(
                      'No exports yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ...vm.exportHistory.map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history, size: 18),
                        title: Text(
                          entry.path,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat(
                            'MMM d, yyyy h:mm a',
                          ).format(entry.exportedAt),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (vm.isBusy)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (vm.info != null)
              _MessageCard(
                color: AppColors.income,
                icon: Icons.check_circle_outline,
                message: vm.info!,
              ),
            if (vm.error != null)
              _MessageCard(
                color: AppColors.expense,
                icon: Icons.error_outline,
                message: vm.error!,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _onExport() async {
    final vm = context.read<DataPortViewModel>();
    final path = await vm.exportData();
    if (!mounted || path == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported: $path')));
  }

  Future<void> _onImportReplace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace existing data?'),
        content: const Text(
          'This will replace Accounts, Transactions, Debts, and Categories with the selected XLSX file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<DataPortViewModel>();
    final result = await vm.importData(replaceExisting: true);
    if (result == null || !mounted) return;

    context.read<AccountsViewModel>().clearError();
    context.read<AccountsViewModel>().refresh();
    context.read<TransactionsViewModel>().clearError();
    context.read<TransactionsViewModel>().refresh();
    context.read<BudgetViewModel>().refresh();
    context.read<DebtViewModel>().clearError();
    context.read<DebtViewModel>().refresh();
    context.read<DashboardViewModel>().refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import completed successfully.')),
    );
  }

  Future<void> _onImportMerge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge data from file?'),
        content: const Text(
          'This will merge rows by ID from the XLSX into existing data. '
          'If an ID exists, the imported row replaces the current row.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<DataPortViewModel>();
    final result = await vm.importData(replaceExisting: false);
    if (result == null || !mounted) return;

    context.read<AccountsViewModel>().clearError();
    context.read<AccountsViewModel>().refresh();
    context.read<TransactionsViewModel>().clearError();
    context.read<TransactionsViewModel>().refresh();
    context.read<BudgetViewModel>().refresh();
    context.read<DebtViewModel>().clearError();
    context.read<DebtViewModel>().refresh();
    context.read<DashboardViewModel>().refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merge import completed successfully.')),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _MessageCard({
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
