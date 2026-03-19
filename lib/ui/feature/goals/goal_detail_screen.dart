import 'package:financier/domain/models/goal_milestone.dart';
import 'package:financier/domain/models/savings_goal.dart';
import 'package:financier/domain/models/transaction.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:financier/ui/feature/goals/goals_view_model.dart';
import 'package:financier/ui/feature/goals/goal_milestones_view_model.dart';
import 'package:financier/ui/feature/transactions/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  SavingsGoal? _findGoalById(GoalsViewModel vm, String id) {
    for (final goal in vm.all) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsVm = context.watch<GoalsViewModel>();
    final milestonesVm = context.watch<GoalMilestonesViewModel>();
    final dateFmt = DateFormat('MMM d, yyyy');
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    final goal = _findGoalById(goalsVm, widget.goalId);

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: Text('Goal not found')),
      );
    }

    final milestones = milestonesVm.milestonesForGoal(goal.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            tooltip: 'Edit Goal',
            onPressed: () =>
                context.pushNamed('goal-edit', pathParameters: {'id': goal.id}),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Contributions'),
              Tab(text: 'Milestones'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  goal: goal,
                  dateFmt: dateFmt,
                  currencyFmt: currencyFmt,
                ),
                _ContributionsTab(goal: goal, currencyFmt: currencyFmt),
                _MilestonesTab(
                  goal: goal,
                  milestones: milestones,
                  currencyFmt: currencyFmt,
                  milestonesVm: milestonesVm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SavingsGoal goal;
  final DateFormat dateFmt;
  final NumberFormat currencyFmt;

  const _OverviewTab({
    required this.goal,
    required this.dateFmt,
    required this.currencyFmt,
  });

  Color _getStatusColor() {
    if (goal.isCompleted) {
      return AppColors.income;
    }
    if (goal.isOverdue) {
      return AppColors.expense;
    }
    if (goal.daysUntilDue <= 30 && goal.daysUntilDue > 0) {
      return AppColors.wants;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final estimatedDate = context
        .watch<GoalsViewModel>()
        .getEstimatedCompletionDate(goal.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Goal Progress',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          goal.isCompleted
                              ? 'Completed'
                              : (goal.isOverdue ? 'Overdue' : goal.statusLabel),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal.percentComplete,
                      minHeight: 12,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(goal.percentComplete * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${currencyFmt.format(goal.currentAmount)} / ${currencyFmt.format(goal.targetAmount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Target Amount',
                    value: currencyFmt.format(goal.targetAmount),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Current Amount',
                    value: currencyFmt.format(goal.currentAmount),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Remaining',
                    value: currencyFmt.format(goal.remainingAmount),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Days Until Due',
                    value: '${goal.daysUntilDue} days',
                    valueColor: goal.daysUntilDue < 0
                        ? AppColors.expense
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timeline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Start Date',
                    value: dateFmt.format(goal.startDate),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Due Date',
                    value: dateFmt.format(goal.dueDate),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Total Days',
                    value: '${goal.daysSinceStart + goal.daysUntilDue} days',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Days Elapsed',
                    value: '${goal.daysSinceStart} days',
                  ),
                  if (estimatedDate != null) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Projected Completion',
                      value: dateFmt.format(estimatedDate),
                      valueColor: estimatedDate.isBefore(goal.dueDate)
                          ? AppColors.income
                          : AppColors.wants,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const _SummaryRow(
                      label: 'Projected Completion',
                      value: 'Add paid/recurring contributions to project',
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!goal.isCompleted &&
              estimatedDate != null &&
              estimatedDate.isAfter(goal.dueDate))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: AppColors.wants.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.wants),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Current pace won\'t meet your due date. Increase contributions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.wants,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributionsTab extends StatelessWidget {
  final SavingsGoal goal;
  final NumberFormat currencyFmt;

  const _ContributionsTab({required this.goal, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final transactionsVm = context.watch<TransactionsViewModel>();
    final dateFmt = DateFormat('MMM d, yyyy');

    // Get all transactions linked to this goal
    final contributionTransactions =
        transactionsVm.filtered.where((t) => t.goalId == goal.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _showContributionSheet(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add Contribution'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Contributions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (contributionTransactions.isEmpty)
                    Center(
                      child: Text(
                        'No contributions yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contributionTransactions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final txn = contributionTransactions[index];
                        return InkWell(
                          onTap: () => _showContributionSheet(context, txn),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                // Paid / unpaid toggle
                                GestureDetector(
                                  onTap: () => context
                                      .read<GoalsViewModel>()
                                      .toggleContributionPaid(txn.id, goal.id),
                                  child: Tooltip(
                                    message: txn.isPaid
                                        ? 'Mark unpaid'
                                        : 'Mark paid',
                                    child: Icon(
                                      txn.isPaid
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: txn.isPaid
                                          ? AppColors.income
                                          : AppColors.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        txn.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateFmt.format(txn.date),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFmt.format(txn.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: txn.isPaid
                                        ? AppColors.income
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContributionSheet(BuildContext context, Transaction? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ContributionSheet(goal: goal, existing: existing),
    );
  }
}

// ---------------------------------------------------------------------------
// Unified add / edit contribution bottom sheet
// ---------------------------------------------------------------------------
class _ContributionSheet extends StatefulWidget {
  final SavingsGoal goal;
  final Transaction? existing; // null = add mode

  const _ContributionSheet({required this.goal, this.existing});

  bool get isEditing => existing != null;

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;

  DateTime _date = DateTime.now();
  String _categoryId = 'cat_savings_transfer';
  String? _accountId;
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  bool _isPaid = false;
  bool _saving = false;

  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(
      text: e?.title ?? '${widget.goal.name} Contribution',
    );
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    if (e != null) {
      _date = e.date;
      _categoryId = e.categoryId;
      _accountId = e.accountId;
      _isRecurring = e.isRecurring;
      _frequency = e.recurrenceFrequency == RecurrenceFrequency.none
          ? RecurrenceFrequency.monthly
          : e.recurrenceFrequency;
      _isPaid = e.isPaid;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txVm = context.watch<TransactionsViewModel>();
    final accountsVm = context.watch<AccountsViewModel>();
    final categories = txVm.categories;
    final accounts = accountsVm.accounts;

    if (categories.isNotEmpty && !categories.any((c) => c.id == _categoryId)) {
      _categoryId = categories.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditing ? 'Edit Contribution' : 'Add Contribution',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Paid / Unpaid — prominent at top, default unpaid
                      Container(
                        decoration: BoxDecoration(
                          color: _isPaid
                              ? AppColors.income.withValues(alpha: 0.08)
                              : AppColors.wants.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isPaid
                                ? AppColors.income
                                : AppColors.textSecondary,
                          ),
                        ),
                        child: SwitchListTile(
                          value: _isPaid,
                          onChanged: (v) => setState(() => _isPaid = v),
                          title: Text(
                            _isPaid ? 'Paid' : 'Unpaid',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isPaid
                                  ? AppColors.income
                                  : AppColors.textSecondary,
                            ),
                          ),
                          subtitle: Text(
                            _isPaid
                                ? 'Counts toward your goal balance'
                                : 'Scheduled — does not affect balance yet',
                            style: const TextStyle(fontSize: 12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          activeThumbColor: AppColors.income,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: 'Name *'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return 'Enter a positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                      if (categories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _categoryId = v ?? _categoryId),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        initialValue: _accountId,
                        decoration: const InputDecoration(
                          labelText: 'Account (optional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ...accounts.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _accountId = v),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                        title: const Text('Recurring'),
                        subtitle: const Text('Repeats on a schedule'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<RecurrenceFrequency>(
                          initialValue: _frequency,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                          ),
                          items: RecurrenceFrequency.values
                              .where((f) => f != RecurrenceFrequency.none)
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(_freqLabel(f)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _frequency = v!),
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
                            : Text(
                                widget.isEditing
                                    ? 'Save Changes'
                                    : 'Add Contribution',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    final amount = double.parse(_amountCtrl.text.trim());
    final freq = _isRecurring ? _frequency : RecurrenceFrequency.none;
    final vm = context.read<GoalsViewModel>();

    if (widget.isEditing) {
      await vm.updateContribution(
        transactionId: widget.existing!.id,
        goalId: widget.goal.id,
        title: _titleCtrl.text.trim(),
        amount: amount,
        date: _date,
        categoryId: _categoryId,
        accountId: _accountId,
        isRecurring: _isRecurring,
        recurrenceFrequency: freq,
        isPaid: _isPaid,
      );
    } else {
      await vm.addContribution(
        goalId: widget.goal.id,
        amount: amount,
        date: _date,
        title: _titleCtrl.text.trim(),
        categoryId: _categoryId,
        accountId: _accountId,
        isRecurring: _isRecurring,
        recurrenceFrequency: freq,
        isPaid: _isPaid,
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  String _freqLabel(RecurrenceFrequency f) {
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

class _MilestonesTab extends StatelessWidget {
  final SavingsGoal goal;
  final List<GoalMilestone> milestones;
  final NumberFormat currencyFmt;
  final GoalMilestonesViewModel milestonesVm;

  const _MilestonesTab({
    required this.goal,
    required this.milestones,
    required this.currencyFmt,
    required this.milestonesVm,
  });

  @override
  Widget build(BuildContext context) {
    final sortedMilestones = List<GoalMilestone>.from(milestones)
      ..sort((a, b) => a.order.compareTo(b.order));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _showAddMilestoneDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Milestone'),
          ),
          const SizedBox(height: 16),
          if (sortedMilestones.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No milestones yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedMilestones.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final milestone = sortedMilestones[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: milestone.isCompleted,
                          onChanged: (checked) {
                            if (checked == true) {
                              milestonesVm.completeMilestone(milestone.id);
                            } else {
                              milestonesVm.uncompleteMilestone(milestone.id);
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                milestone.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: milestone.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFmt.format(milestone.targetAmount),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () =>
                              _confirmDeleteMilestone(context, milestone),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showAddMilestoneDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Milestone Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (name.isNotEmpty && amount != null && amount > 0) {
                milestonesVm.addMilestone(
                  goalId: goal.id,
                  name: name,
                  targetAmount: amount,
                  order: milestones.length + 1,
                );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMilestone(BuildContext context, GoalMilestone milestone) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: Text('Remove "${milestone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              milestonesVm.deleteMilestone(milestone.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
        ),
      ],
    );
  }
}
