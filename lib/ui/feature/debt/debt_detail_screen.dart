import 'package:financier/domain/models/debt.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/debt/debt_view_model.dart';
import 'package:financier/ui/feature/transactions/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebtDetailScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late final TextEditingController _customPaymentCtrl;
  final _currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  bool _initialized = false;

  bool _isRecurringPayment = true;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.monthly;
  DateTime _paymentStartDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _customPaymentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _customPaymentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtVm = context.watch<DebtViewModel>();
    final txVm = context.watch<TransactionsViewModel>();
    final debt = debtVm.findById(widget.debtId);

    if (debt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debt Details')),
        body: const Center(child: Text('Debt not found')),
      );
    }

    if (!_initialized) {
      _customPaymentCtrl.text = debt.customPayment?.toStringAsFixed(2) ?? '';
      _initialized = true;
    }

    final linkedPayments = txVm.transactionsForDebt(debt.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.name),
        actions: [
          IconButton(
            tooltip: 'Edit Debt',
            onPressed: () =>
                context.pushNamed('debt-edit', pathParameters: {'id': debt.id}),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DebtInfoCard(debt: debt, currencyFmt: _currencyFmt),
          const SizedBox(height: 12),
          _CustomPaymentCard(
            controller: _customPaymentCtrl,
            onSave: () => _saveCustomPayment(debtVm, debt.id),
          ),
          const SizedBox(height: 12),
          _buildPaymentTransactionCard(debtVm, debt),
          const SizedBox(height: 12),
          _LinkedPaymentsCard(
            linkedPayments: linkedPayments,
            currencyFmt: _currencyFmt,
            onEdit: (tx) => context.pushNamed(
              'transaction-edit',
              pathParameters: {'id': tx.id},
            ),
            onDelete: (tx) => _deleteLinkedPayment(txVm, tx),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentTransactionCard(DebtViewModel debtVm, Debt debt) {
    final minimumPayment = debt.minimumPayment ?? 0;
    final customPayment = debt.customPayment ?? 0;
    final totalPlanned = minimumPayment + customPayment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Debt Payment Transaction',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum + Custom = ${_currencyFmt.format(totalPlanned)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isRecurringPayment,
              onChanged: (value) {
                setState(() => _isRecurringPayment = value);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring payment transaction'),
            ),
            if (_isRecurringPayment) ...[
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: _recurrenceFrequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: RecurrenceFrequency.values
                    .where((f) => f != RecurrenceFrequency.none)
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(_frequencyLabel(f)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurrenceFrequency = value);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
            InkWell(
              onTap: _pickPaymentStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_paymentStartDate),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: debtVm.isLoading
                  ? null
                  : () => _createPaymentTransaction(debtVm, debt),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Transactions'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPaymentStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paymentStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _paymentStartDate = selected);
    }
  }

  Future<void> _saveCustomPayment(DebtViewModel vm, String debtId) async {
    final raw = _customPaymentCtrl.text.trim();
    final parsed = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && parsed == null) {
      _showSnackBar('Enter a valid custom payment amount.');
      return;
    }
    if (parsed != null && parsed < 0) {
      _showSnackBar('Custom payment must be zero or greater.');
      return;
    }

    await vm.updateCustomPayment(debtId, parsed);
    if (!mounted) return;
    _showSnackBar('Custom payment updated.');
  }

  Future<void> _createPaymentTransaction(DebtViewModel vm, Debt debt) async {
    final createdCount = await vm.addDebtPaymentTransactions(
      debt: debt,
      startDate: _paymentStartDate,
      isRecurring: _isRecurringPayment,
      recurrenceFrequency: _recurrenceFrequency,
    );

    if (!mounted) return;
    if (vm.error != null) {
      _showSnackBar(vm.error!);
      vm.clearError();
      return;
    }

    if (createdCount == 0) {
      _showSnackBar('No payment transactions were added.');
      return;
    }

    _showSnackBar(
      createdCount == 1
          ? '1 debt payment transaction added.'
          : '$createdCount debt payment transactions added.',
    );
  }

  Future<void> _deleteLinkedPayment(
    TransactionsViewModel txVm,
    Transaction tx,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await txVm.deleteTransaction(tx.id);
    if (!mounted) return;
    _showSnackBar('Transaction deleted.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _frequencyLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Every 2 Weeks';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.annually:
        return 'Annually';
      case RecurrenceFrequency.none:
        return 'None';
    }
  }
}

class _DebtInfoCard extends StatelessWidget {
  final Debt debt;
  final NumberFormat currencyFmt;

  const _DebtInfoCard({required this.debt, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debt Details',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _DetailRow(label: 'Name', value: debt.name),
            _DetailRow(label: 'Type', value: debt.debtTypeLabel),
            _DetailRow(
              label: 'Balance',
              value: currencyFmt.format(debt.balance),
            ),
            _DetailRow(
              label: 'Interest Rate',
              value: debt.interestRate == null
                  ? 'Not set'
                  : '${debt.interestRate!.toStringAsFixed(2)}% APR',
            ),
            _DetailRow(
              label: 'Minimum Payment',
              value: debt.minimumPayment == null
                  ? 'Not set'
                  : currencyFmt.format(debt.minimumPayment),
            ),
            _DetailRow(
              label: 'Custom Payment',
              value: debt.customPayment == null
                  ? 'Not set'
                  : currencyFmt.format(debt.customPayment),
            ),
            _DetailRow(
              label: 'Due Day',
              value: debt.dueDay == null ? 'Not set' : '${debt.dueDay}',
            ),
            _DetailRow(label: 'Note', value: debt.note ?? '—'),
          ],
        ),
      ),
    );
  }
}

class _CustomPaymentCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _CustomPaymentCard({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Monthly Payment',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Additional amount',
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onSave,
              child: const Text('Update Custom Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedPaymentsCard extends StatelessWidget {
  final List<Transaction> linkedPayments;
  final NumberFormat currencyFmt;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const _LinkedPaymentsCard({
    required this.linkedPayments,
    required this.currencyFmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Linked Debt Payment Transactions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (linkedPayments.isEmpty)
              const Text(
                'No linked payment transactions yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...linkedPayments.map(
                (tx) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(tx.title),
                  subtitle: Text(
                    '${DateFormat('MMM d, yyyy').format(tx.date)}'
                    '${tx.isRecurring ? ' • ${tx.recurrenceLabel}' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit(tx);
                      if (value == 'delete') onDelete(tx);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  leading: Text(
                    currencyFmt.format(tx.amount),
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
