import 'package:financier/domain/models/debt.dart';
import 'package:financier/ui/feature/debt/debt_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddEditDebtScreen extends StatefulWidget {
  final String? debtId;
  const AddEditDebtScreen({super.key, this.debtId});

  bool get isEditing => debtId != null;

  @override
  State<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends State<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _interestCtrl;
  late final TextEditingController _minPaymentCtrl;
  late final TextEditingController _customPaymentCtrl;
  late final TextEditingController _dueDayCtrl;
  late final TextEditingController _noteCtrl;

  DebtType _debtType = DebtType.personalLoan;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _balanceCtrl = TextEditingController();
    _interestCtrl = TextEditingController();
    _minPaymentCtrl = TextEditingController();
    _customPaymentCtrl = TextEditingController();
    _dueDayCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<DebtViewModel>();
        final existing = vm.findById(widget.debtId!);
        if (existing != null) {
          _nameCtrl.text = existing.name;
          _balanceCtrl.text = existing.balance.toStringAsFixed(2);
          _interestCtrl.text = existing.interestRate?.toStringAsFixed(2) ?? '';
          _minPaymentCtrl.text =
              existing.minimumPayment?.toStringAsFixed(2) ?? '';
          _customPaymentCtrl.text =
              existing.customPayment?.toStringAsFixed(2) ?? '';
          _dueDayCtrl.text = existing.dueDay?.toString() ?? '';
          _noteCtrl.text = existing.note ?? '';
          setState(() => _debtType = existing.debtType);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _interestCtrl.dispose();
    _minPaymentCtrl.dispose();
    _customPaymentCtrl.dispose();
    _dueDayCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Debt' : 'Add Debt'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Debt Name *',
                  hintText: 'e.g. Car Loan, Visa Card',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DebtType>(
                initialValue: _debtType,
                decoration: const InputDecoration(labelText: 'Debt Type *'),
                items: DebtType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.debtTypeLabel),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _debtType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current Balance *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Balance is required';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestCtrl,
                decoration: const InputDecoration(
                  labelText: 'Interest Rate % (optional)',
                  hintText: 'e.g. 5.99',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPaymentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Minimum Monthly Payment (optional)',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customPaymentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Custom Monthly Payment (optional)',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDayCtrl,
                decoration: const InputDecoration(
                  labelText: 'Due Day of Month (optional)',
                  hintText: 'e.g. 15',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1 || n > 31) {
                    return 'Enter a day between 1 and 31';
                  }
                  return null;
                },
              ),
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
                    : Text(widget.isEditing ? 'Save Changes' : 'Add Debt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final vm = context.read<DebtViewModel>();

    double? parseValue(TextEditingController ctrl) {
      final s = ctrl.text.trim();
      return s.isEmpty ? null : double.tryParse(s);
    }

    int? dueDay;
    if (_dueDayCtrl.text.trim().isNotEmpty) {
      dueDay = int.tryParse(_dueDayCtrl.text.trim());
    }

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (widget.isEditing) {
      final existing = vm.findById(widget.debtId!);
      if (existing != null) {
        await vm.updateDebt(
          existing.copyWith(
            name: _nameCtrl.text.trim(),
            debtType: _debtType,
            balance: double.parse(_balanceCtrl.text.trim()),
            interestRate: parseValue(_interestCtrl),
            minimumPayment: parseValue(_minPaymentCtrl),
            customPayment: parseValue(_customPaymentCtrl),
            dueDay: dueDay,
            note: note,
            clearInterestRate: _interestCtrl.text.trim().isEmpty,
            clearMinimumPayment: _minPaymentCtrl.text.trim().isEmpty,
            clearCustomPayment: _customPaymentCtrl.text.trim().isEmpty,
            clearDueDay: _dueDayCtrl.text.trim().isEmpty,
            clearNote: note == null,
          ),
        );
      }
    } else {
      await vm.addDebt(
        name: _nameCtrl.text.trim(),
        debtType: _debtType,
        balance: double.parse(_balanceCtrl.text.trim()),
        interestRate: parseValue(_interestCtrl),
        minimumPayment: parseValue(_minPaymentCtrl),
        customPayment: parseValue(_customPaymentCtrl),
        dueDay: dueDay,
        note: note,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }
}
