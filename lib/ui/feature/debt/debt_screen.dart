import 'package:financier/domain/models/debt.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/debt/debt_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final _monthFmt = DateFormat('MMM yyyy');
  String? _selectedDebtId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DebtViewModel>();
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    if (vm.debts.isNotEmpty) {
      final hasSelected =
          _selectedDebtId != null &&
          vm.debts.any((debt) => debt.id == _selectedDebtId);
      _selectedDebtId = hasSelected ? _selectedDebtId : vm.debts.first.id;
    } else {
      _selectedDebtId = null;
    }

    final selectedDebt = _selectedDebtId == null
        ? null
        : vm.findById(_selectedDebtId!);
    final schedule = selectedDebt == null
        ? const <DebtAmortizationRow>[]
        : vm.amortizationForDebt(debtId: selectedDebt.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Debt')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('debt-add'),
        child: const Icon(Icons.add),
      ),
      body: vm.debts.isEmpty
          ? _EmptyState(onAdd: () => context.pushNamed('debt-add'))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _TotalDebtCard(
                    total: vm.totalBalance,
                    minimumPayments: vm.totalMinimumPayment,
                    currencyFmt: currencyFmt,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _DebtAmortizationCard(
                    debts: vm.debts,
                    selectedDebtId: _selectedDebtId,
                    monthFmt: _monthFmt,
                    currencyFmt: currencyFmt,
                    schedule: schedule,
                    onDebtChanged: (debtId) {
                      setState(() => _selectedDebtId = debtId);
                    },
                  ),
                ),
                SliverList.separated(
                  itemCount: vm.debts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) => _DebtTile(
                    debt: vm.debts[i],
                    currencyFmt: currencyFmt,
                    onTap: () => ctx.pushNamed(
                      'debt-detail',
                      pathParameters: {'id': vm.debts[i].id},
                    ),
                    onEdit: () => ctx.pushNamed(
                      'debt-edit',
                      pathParameters: {'id': vm.debts[i].id},
                    ),
                    onDelete: () => _confirmDelete(ctx, vm, vm.debts[i]),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
    );
  }

  void _confirmDelete(BuildContext context, DebtViewModel vm, Debt debt) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Debt'),
        content: Text('Remove "${debt.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              vm.deleteDebt(debt.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DebtAmortizationCard extends StatelessWidget {
  final List<Debt> debts;
  final String? selectedDebtId;
  final DateFormat monthFmt;
  final NumberFormat currencyFmt;
  final List<DebtAmortizationRow> schedule;
  final ValueChanged<String> onDebtChanged;

  const _DebtAmortizationCard({
    required this.debts,
    required this.selectedDebtId,
    required this.monthFmt,
    required this.currencyFmt,
    required this.schedule,
    required this.onDebtChanged,
  });

  @override
  Widget build(BuildContext context) {
    final previewRows = schedule.take(36).toList();
    final payoff = schedule.isNotEmpty ? schedule.last : null;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ExpansionTile(
        title: const Text('Debt Payoff Amortization'),
        subtitle: Text(
          payoff == null
              ? 'No projection available'
              : 'Estimated payoff: ${monthFmt.format(payoff.month)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedDebtId,
            decoration: const InputDecoration(labelText: 'Debt'),
            items: debts
                .map(
                  (debt) =>
                      DropdownMenuItem(value: debt.id, child: Text(debt.name)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onDebtChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          if (previewRows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Set debt balance and payments to see an amortization table.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Month')),
                  DataColumn(label: Text('Start')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Interest')),
                  DataColumn(label: Text('Principal')),
                  DataColumn(label: Text('End')),
                ],
                rows: previewRows
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(monthFmt.format(row.month))),
                          DataCell(
                            Text(currencyFmt.format(row.startingBalance)),
                          ),
                          DataCell(Text(currencyFmt.format(row.payment))),
                          DataCell(Text(currencyFmt.format(row.interest))),
                          DataCell(Text(currencyFmt.format(row.principal))),
                          DataCell(Text(currencyFmt.format(row.endingBalance))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            if (schedule.length > previewRows.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Showing first ${previewRows.length} months of ${schedule.length}.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TotalDebtCard extends StatelessWidget {
  final double total;
  final double minimumPayments;
  final NumberFormat currencyFmt;

  const _TotalDebtCard({
    required this.total,
    required this.minimumPayments,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.debtAccent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Debt',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFmt.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (minimumPayments > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Min. monthly payments: ${currencyFmt.format(minimumPayments)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtTile({
    required this.debt,
    required this.currencyFmt,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.debtAccent.withValues(alpha: 0.1),
        child: const Icon(Icons.credit_card, color: AppColors.debtAccent),
      ),
      title: Text(
        debt.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            debt.debtTypeLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (debt.minimumPayment != null)
            Text(
              'Min: ${currencyFmt.format(debt.minimumPayment!)} / mo',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          if (debt.interestRate != null)
            Text(
              '${debt.interestRate!.toStringAsFixed(2)}% APR',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            currencyFmt.format(debt.balance),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.debtAccent,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.credit_card_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          const Text(
            'No debts tracked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a debt to track your balances',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Debt'),
          ),
        ],
      ),
    );
  }
}
