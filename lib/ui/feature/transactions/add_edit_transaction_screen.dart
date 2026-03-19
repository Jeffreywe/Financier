import 'package:financier/domain/models/budget_category.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:financier/ui/feature/transactions/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final String? transactionId;
  const AddEditTransactionScreen({super.key, this.transactionId});

  bool get isEditing => transactionId != null;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  bool _saving = false;

  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<TransactionsViewModel>();
        final tx = vm.findById(widget.transactionId!);
        if (tx != null) {
          _titleCtrl.text = tx.title;
          _amountCtrl.text = tx.amount.toStringAsFixed(2);
          _noteCtrl.text = tx.note ?? '';
          setState(() {
            _type = tx.type;
            _categoryId = tx.categoryId;
            _accountId = tx.accountId;
            _date = tx.date;
            _isRecurring = tx.isRecurring;
            _frequency = tx.recurrenceFrequency;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txVm = context.watch<TransactionsViewModel>();
    final accountsVm = context.watch<AccountsViewModel>();
    final categories = txVm.categories;
    final accounts = accountsVm.accounts;

    // Default category if first entry
    if (_categoryId == null && categories.isNotEmpty) {
      final defaultCat = categories
          .where(
            (c) => _type == TransactionType.income
                ? c.id == 'cat_income_paycheck'
                : _type == TransactionType.note
                ? c.id == 'cat_other'
                : c.bucket != BudgetBucket.needs || c.id == 'cat_rent',
          )
          .firstOrNull;
      _categoryId = defaultCat?.id ?? categories.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.note,
                    label: Text('Note'),
                    icon: Icon(Icons.sticky_note_2_outlined),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Rent, Paycheck, Groceries',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),
              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_dateFmt.format(_date)),
                ),
              ),
              const SizedBox(height: 16),
              // Account (optional)
              DropdownButtonFormField<String?>(
                initialValue: _accountId,
                decoration: const InputDecoration(
                  labelText: 'Account (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...accounts.map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 16),
              // Recurring
              SwitchListTile(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                title: const Text('Recurring'),
                subtitle: const Text('This transaction repeats on a schedule'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _frequency,
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
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Add Transaction',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final vm = context.read<TransactionsViewModel>();
    final amount = double.parse(_amountCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (widget.isEditing) {
      final existing = vm.findById(widget.transactionId!);
      if (existing != null) {
        await vm.updateTransaction(
          existing.copyWith(
            title: _titleCtrl.text.trim(),
            amount: amount,
            type: _type,
            categoryId: _categoryId!,
            date: _date,
            isRecurring: _isRecurring,
            recurrenceFrequency: _isRecurring
                ? _frequency
                : RecurrenceFrequency.none,
            accountId: _accountId,
            note: note,
            clearNote: note == null,
            clearAccountId: _accountId == null,
          ),
        );
      }
    } else {
      await vm.addTransaction(
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _categoryId!,
        date: _date,
        isRecurring: _isRecurring,
        recurrenceFrequency: _isRecurring
            ? _frequency
            : RecurrenceFrequency.none,
        accountId: _accountId,
        note: note,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  String _frequencyLabel(RecurrenceFrequency f) {
    switch (f) {
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
