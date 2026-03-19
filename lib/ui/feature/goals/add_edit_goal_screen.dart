import 'package:financier/domain/models/savings_goal.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:financier/ui/feature/goals/goals_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddEditGoalScreen extends StatefulWidget {
  final String? goalId;

  const AddEditGoalScreen({super.key, this.goalId});

  bool get isEditing => goalId != null;

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetAmountCtrl;
  late final TextEditingController _currentAmountCtrl;
  late final TextEditingController _recurringAmountCtrl;

  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 365));
  String? _selectedAccountId;
  bool _isRecurringContribution = false;
  ContributionFrequency _recurringFrequency = ContributionFrequency.monthly;
  bool _autoGenerateTransaction = false;
  bool _saving = false;

  SavingsGoal? _findGoalById(GoalsViewModel vm, String? id) {
    if (id == null) return null;
    for (final goal in vm.all) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _targetAmountCtrl = TextEditingController();
    _currentAmountCtrl = TextEditingController();
    _recurringAmountCtrl = TextEditingController();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<GoalsViewModel>();
        final existing = vm.selectedGoal;
        if (existing == null) {
          // Get from repository by ID
          final goal = _findGoalById(vm, widget.goalId);

          if (goal != null) {
            _nameCtrl.text = goal.name;
            _targetAmountCtrl.text = goal.targetAmount.toStringAsFixed(2);
            _currentAmountCtrl.text = goal.currentAmount.toStringAsFixed(2);
            if (goal.recurringAmount != null) {
              _recurringAmountCtrl.text = goal.recurringAmount!.toStringAsFixed(
                2,
              );
            }
            _selectedAccountId = goal.linkedAccountId;
            _startDate = goal.startDate;
            _dueDate = goal.dueDate;
            _isRecurringContribution = goal.isRecurringContribution;
            _recurringFrequency = goal.recurringFrequency;
            _autoGenerateTransaction = goal.autoGenerateTransaction;
            setState(() {});
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetAmountCtrl.dispose();
    _currentAmountCtrl.dispose();
    _recurringAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final vm = context.read<GoalsViewModel>();

    final targetAmount = double.parse(_targetAmountCtrl.text.trim());
    final currentAmount = double.parse(_currentAmountCtrl.text.trim());
    final recurringAmount = _isRecurringContribution
        ? double.tryParse(_recurringAmountCtrl.text.trim())
        : null;

    try {
      if (widget.isEditing) {
        final existing = _findGoalById(vm, widget.goalId);

        if (existing != null) {
          final updated = existing.copyWith(
            name: _nameCtrl.text.trim(),
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            linkedAccountId: _selectedAccountId,
            startDate: _startDate,
            dueDate: _dueDate,
            isRecurringContribution: _isRecurringContribution,
            recurringAmount: recurringAmount,
            recurringFrequency: _recurringFrequency,
            autoGenerateTransaction: _autoGenerateTransaction,
            updatedAt: DateTime.now(),
          );
          await vm.updateGoal(updated);
        }
      } else {
        await vm.createGoal(
          name: _nameCtrl.text.trim(),
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          startDate: _startDate,
          dueDate: _dueDate,
          linkedAccountId: _selectedAccountId,
          isRecurringContribution: _isRecurringContribution,
          recurringAmount: recurringAmount,
          recurringFrequency: _recurringFrequency,
          autoGenerateTransaction: _autoGenerateTransaction,
        );
      }

      if (!mounted) return;
      if (vm.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(vm.error!)));
        setState(() => _saving = false);
        return;
      }

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsVm = context.watch<AccountsViewModel>();
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Goal' : 'Add Goal'),
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
                  labelText: 'Goal Name *',
                  hintText: 'e.g. Emergency Fund, Vacation',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Amount *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Target amount is required';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  if (parsed <= 0) {
                    return 'Target amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentAmountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current Amount *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Current amount is required';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  if (parsed < 0) {
                    return 'Current amount cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Linked Account (optional)',
                  hintText: 'Select an account...',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...accountsVm.accounts.map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedAccountId = value),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dates',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFmt.format(_startDate)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFmt.format(_dueDate)),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: _isRecurringContribution,
                onChanged: (value) =>
                    setState(() => _isRecurringContribution = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring Contribution'),
                subtitle: const Text('Add regular contributions to this goal'),
              ),
              if (_isRecurringContribution) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recurringAmountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contribution Amount',
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (_isRecurringContribution) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Contribution amount is required';
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null) {
                        return 'Enter a valid number';
                      }
                      if (parsed <= 0) {
                        return 'Contribution must be greater than 0';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ContributionFrequency>(
                  initialValue: _recurringFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: ContributionFrequency.values
                      .where((f) => f != ContributionFrequency.none)
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(_frequencyLabel(f)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _recurringFrequency = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _autoGenerateTransaction,
                  onChanged: (value) =>
                      setState(() => _autoGenerateTransaction = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-generate Transactions'),
                  subtitle: const Text(
                    'Automatically create contribution transactions',
                  ),
                ),
              ],
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
                    : Text(widget.isEditing ? 'Save Changes' : 'Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _frequencyLabel(ContributionFrequency frequency) {
    switch (frequency) {
      case ContributionFrequency.weekly:
        return 'Weekly';
      case ContributionFrequency.biweekly:
        return 'Biweekly';
      case ContributionFrequency.monthly:
        return 'Monthly';
      case ContributionFrequency.quarterly:
        return 'Quarterly';
      case ContributionFrequency.annually:
        return 'Annually';
      case ContributionFrequency.none:
        return 'None';
    }
  }
}
