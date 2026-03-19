import 'package:financier/domain/models/account.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddEditAccountScreen extends StatefulWidget {
  final String? accountId;
  const AddEditAccountScreen({super.key, this.accountId});

  bool get isEditing => accountId != null;

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _noteCtrl;
  AccountType _type = AccountType.checking;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _balanceCtrl = TextEditingController();
    _noteCtrl = TextEditingController();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<AccountsViewModel>();
        final existing = vm.findById(widget.accountId!);
        if (existing != null) {
          _nameCtrl.text = existing.name;
          _balanceCtrl.text = existing.balance.toStringAsFixed(2);
          _noteCtrl.text = existing.note ?? '';
          setState(() => _type = existing.type);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Account' : 'Add Account'),
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
                  labelText: 'Account Name *',
                  hintText: 'e.g. Chase Checking',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Account Type *'),
                items: AccountType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_labelForType(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
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
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Joint account with spouse',
                ),
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
                    : Text(widget.isEditing ? 'Save Changes' : 'Add Account'),
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
    final vm = context.read<AccountsViewModel>();
    final balance = double.parse(_balanceCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (widget.isEditing) {
      final existing = vm.findById(widget.accountId!);
      if (existing != null) {
        await vm.updateAccount(
          existing.copyWith(
            name: _nameCtrl.text.trim(),
            type: _type,
            balance: balance,
            note: note,
            clearNote: note == null,
          ),
        );
      }
    } else {
      await vm.addAccount(
        name: _nameCtrl.text.trim(),
        type: _type,
        balance: balance,
        note: note,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  String _labelForType(AccountType t) {
    switch (t) {
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'Savings';
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
      case AccountType.other:
        return 'Other';
    }
  }
}
