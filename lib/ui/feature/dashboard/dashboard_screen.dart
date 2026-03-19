import 'package:financier/domain/models/transaction.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/dashboard/dashboard_view_model.dart';
import 'package:financier/ui/feature/goals/goal_milestones_view_model.dart';
import 'package:financier/ui/feature/goals/goals_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final monthName = DateFormat('MMMM yyyy').format(vm.selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Import / Export',
            onPressed: () => context.pushNamed('data-port'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Transaction',
            onPressed: () => context.pushNamed('transaction-add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => vm.refresh(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Month label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: vm.previousMonth,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: vm.nextMonth,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Income',
                      value: currencyFmt.format(vm.monthlyIncome),
                      color: AppColors.income,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Expenses',
                      value: currencyFmt.format(vm.monthlyExpenses),
                      color: AppColors.expense,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Left to budget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LeftToBudgetCard(
                left: vm.leftToBudget,
                currencyFmt: currencyFmt,
              ),
            ),
            const SizedBox(height: 12),
            // Account balance + total debt row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _TapCard(
                      label: 'Account Balance',
                      value: currencyFmt.format(vm.totalAccountBalance),
                      color: AppColors.primary,
                      onTap: () => context.goNamed('accounts'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TapCard(
                      label: 'Total Debt',
                      value: currencyFmt.format(vm.totalDebt),
                      color: AppColors.debtAccent,
                      onTap: () => context.goNamed('debt'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Budget shortcut
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed('budget'),
                icon: const Icon(Icons.pie_chart_outline),
                label: const Text('View 50/30/20 Budget'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _MonthCalendarCard(vm: vm, currencyFmt: currencyFmt),
            const SizedBox(height: 12),
            // Future Outlook (biweekly + monthly)
            _FutureOutlookCard(vm: vm, currencyFmt: currencyFmt),
            const SizedBox(height: 12),
            // Upcoming recurring
            if (vm.upcomingItems.isNotEmpty) ...[
              _SectionHeader(
                title: 'Upcoming (Next 7 Days)',
                onViewAll: () => context.goNamed('transactions'),
              ),
              ...vm.upcomingItems.map(
                (item) =>
                    _UpcomingTile(vm: vm, item: item, currencyFmt: currencyFmt),
              ),
              const SizedBox(height: 8),
            ],
            // Recent transactions
            _SectionHeader(
              title: 'Recent Transactions',
              onViewAll: () => context.goNamed('transactions'),
            ),
            if (vm.recentTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'No transactions yet. Tap + to add one.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...vm.recentTransactions.map(
                (tx) => _RecentTxTile(
                  vm: vm,
                  transaction: tx,
                  currencyFmt: currencyFmt,
                  onTap: () => context.pushNamed(
                    'transaction-edit',
                    pathParameters: {'id': tx.id},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftToBudgetCard extends StatelessWidget {
  final double left;
  final NumberFormat currencyFmt;

  const _LeftToBudgetCard({required this.left, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final positive = left >= 0;
    return Card(
      color: positive ? AppColors.primaryContainer : const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Left to budget',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            Text(
              currencyFmt.format(left),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: positive ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _TapCard({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to view',
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          TextButton(onPressed: onViewAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _MonthCalendarCard extends StatefulWidget {
  final DashboardViewModel vm;
  final NumberFormat currencyFmt;

  const _MonthCalendarCard({required this.vm, required this.currencyFmt});

  @override
  State<_MonthCalendarCard> createState() => _MonthCalendarCardState();
}

class _MonthCalendarCardState extends State<_MonthCalendarCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final month = widget.vm.selectedMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // Sunday-first
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: _expanded ? 'Collapse calendar' : 'Expand calendar',
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  _LegendDot(color: AppColors.expense, label: 'Unpaid'),
                  SizedBox(width: 8),
                  _LegendDot(color: AppColors.income, label: 'Paid'),
                  SizedBox(width: 8),
                  _LegendDot(color: AppColors.wants, label: 'Income'),
                ],
              ),
            ],
            if (_expanded) ...[
              const SizedBox(height: 8),
              Row(
                children: weekdays
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - startOffset + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final day = DateTime(month.year, month.month, dayNumber);
                  final items = widget.vm.currentMonthItemsForDay(day);
                  final totalCount = items.length;
                  final incomeCount = items
                      .where((e) => e.type == TransactionType.income)
                      .length;
                  final paidExpenseCount = items
                      .where(
                        (e) => e.type == TransactionType.expense && e.isPaid,
                      )
                      .length;
                  final unpaidExpenseCount = items
                      .where(
                        (e) => e.type == TransactionType.expense && !e.isPaid,
                      )
                      .length;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: totalCount == 0
                        ? null
                        : () => _showDayTransactions(
                            context: context,
                            day: day,
                            items: items,
                          ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dayNumber',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (totalCount > 0)
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                if (unpaidExpenseCount > 0)
                                  _MiniIndicator(
                                    count: unpaidExpenseCount,
                                    color: AppColors.expense,
                                  ),
                                if (paidExpenseCount > 0)
                                  _MiniIndicator(
                                    count: paidExpenseCount,
                                    color: AppColors.income,
                                  ),
                                if (incomeCount > 0)
                                  _MiniIndicator(
                                    count: incomeCount,
                                    color: AppColors.wants,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDayTransactions({
    required BuildContext context,
    required DateTime day,
    required List<OutlookItem> items,
  }) {
    final dayFmt = DateFormat('EEE, MMM d');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final refreshed = widget.vm.currentMonthItemsForDay(day);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayFmt.format(day),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: refreshed.length,
                        itemBuilder: (context, i) {
                          final item = refreshed[i];
                          final isIncome = item.type == TransactionType.income;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: InkWell(
                              onTap: () async {
                                await widget.vm.toggleOutlookItemPaid(item);
                                context.read<GoalsViewModel>().refresh();
                                context.read<GoalMilestonesViewModel>().refresh();
                                setSheetState(() {});
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Icon(
                                item.isPaid
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: item.isPaid
                                    ? AppColors.income
                                    : AppColors.textSecondary,
                              ),
                            ),
                            title: Text(item.title),
                            subtitle: Text(item.isPaid ? 'Paid' : 'Unpaid'),
                            trailing: Text(
                              (isIncome ? '+' : '-') +
                                  widget.currencyFmt.format(item.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isIncome
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniIndicator extends StatelessWidget {
  final int count;
  final Color color;

  const _MiniIndicator({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final DashboardViewModel vm;
  final ({Transaction transaction, DateTime nextDate}) item;
  final NumberFormat currencyFmt;

  const _UpcomingTile({
    required this.vm,
    required this.item,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final tx = item.transaction;
    final isIncome = tx.type == TransactionType.income;
    final isExpense = tx.type == TransactionType.expense;
    final isNote = tx.type == TransactionType.note;
    final isPaid = vm.isOccurrencePaid(tx.id, item.nextDate);
    final dateFmt = DateFormat('MMM d');
    return ListTile(
      leading: InkWell(
        onTap: () async {
          await vm.toggleOccurrencePaid(tx.id, item.nextDate);
          context.read<GoalsViewModel>().refresh();
          context.read<GoalMilestonesViewModel>().refresh();
        },
        borderRadius: BorderRadius.circular(14),
        child: Icon(
          isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isPaid ? AppColors.income : AppColors.textSecondary,
        ),
      ),
      title: Text(
        tx.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${dateFmt.format(item.nextDate)} • ${isPaid ? 'Paid' : 'Unpaid'}${isNote ? ' • Note' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        isNote
            ? currencyFmt.format(tx.amount)
            : (isIncome ? '+' : '-') + currencyFmt.format(tx.amount),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isIncome
              ? AppColors.income
              : isExpense
              ? AppColors.expense
              : AppColors.neutral,
        ),
      ),
    );
  }
}

class _RecentTxTile extends StatelessWidget {
  final DashboardViewModel vm;
  final Transaction transaction;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;

  const _RecentTxTile({
    required this.vm,
    required this.transaction,
    required this.currencyFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final isNote = transaction.type == TransactionType.note;
    final isPaid = vm.isOccurrencePaid(transaction.id, transaction.date);
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final txDay = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    final isOverdue = !isPaid && txDay.isBefore(dayStart);
    final dateFmt = DateFormat('MMM d');
    return ListTile(
      onTap: onTap,
      leading: InkWell(
        onTap: () async {
          await vm.toggleOccurrencePaid(transaction.id, transaction.date);
          context.read<GoalsViewModel>().refresh();
          context.read<GoalMilestonesViewModel>().refresh();
        },
        borderRadius: BorderRadius.circular(14),
        child: Icon(
          isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isPaid ? AppColors.income : AppColors.textSecondary,
        ),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isOverdue
            ? '${dateFmt.format(transaction.date)} • Unpaid • Overdue${isNote ? ' • Note' : ''}'
            : '${dateFmt.format(transaction.date)} • ${isPaid ? 'Paid' : 'Unpaid'}${isNote ? ' • Note' : ''}',
        style: TextStyle(
          fontSize: 12,
          color: isOverdue ? AppColors.expense : AppColors.textSecondary,
          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Text(
        isNote
            ? currencyFmt.format(transaction.amount)
            : (isIncome ? '+' : '-') + currencyFmt.format(transaction.amount),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isIncome
              ? AppColors.income
              : isExpense
              ? AppColors.expense
              : AppColors.neutral,
        ),
      ),
    );
  }
}

// ── Future Outlook card ───────────────────────────────────────────────────────

class _FutureOutlookCard extends StatefulWidget {
  final DashboardViewModel vm;
  final NumberFormat currencyFmt;

  const _FutureOutlookCard({required this.vm, required this.currencyFmt});

  @override
  State<_FutureOutlookCard> createState() => _FutureOutlookCardState();
}

class _FutureOutlookCardState extends State<_FutureOutlookCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const int _currentPeriodIndex = 1;
  int _periodIndex =
      1; // Biweekly defaults to current (Previous, Current, Next)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _periodIndex = _currentPeriodIndex;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMonthly = _tabController.index == 1;
    final periods = isMonthly
        ? widget.vm.monthlyOutlook
        : widget.vm.biweeklyOutlook;
    final fmt = widget.currencyFmt;
    final dateFmt = DateFormat('MMM d');

    // Clamp period index to valid range
    final displayIndex = _periodIndex.clamp(0, periods.length - 1);
    final currentPeriod = periods[displayIndex];
    final hasNext = displayIndex < periods.length - 1;
    final hasPrev = displayIndex > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text(
            'Future Outlook',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Biweekly'),
            Tab(text: 'Monthly'),
          ],
        ),
        const SizedBox(height: 8),
        // Display single period card with navigation
        _PeriodCard(
          vm: widget.vm,
          period: currentPeriod,
          fmt: fmt,
          dateFmt: dateFmt,
          isBiweekly: !isMonthly,
          onNext: hasNext ? () => setState(() => _periodIndex++) : null,
          onPrev: hasPrev ? () => setState(() => _periodIndex--) : null,
          onCurrent: !isMonthly && displayIndex != _currentPeriodIndex
              ? () => setState(() => _periodIndex = _currentPeriodIndex)
              : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final DashboardViewModel vm;
  final OutlookPeriod period;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final bool isBiweekly;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onCurrent;

  const _PeriodCard({
    required this.vm,
    required this.period,
    required this.fmt,
    required this.dateFmt,
    required this.isBiweekly,
    this.onNext,
    this.onPrev,
    this.onCurrent,
  });

  String _incomeLabel(OutlookPeriod p) =>
      p.showAccountBalanceLabel ? 'Account Balance' : 'Income';

  @override
  Widget build(BuildContext context) {
    final isPositiveNet = period.net >= 0;
    final scheduledItems = period.items
        .where((i) => i.type != TransactionType.note)
        .toList();
    final noteItems = vm.allNotesItems;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onPrev != null)
                  TextButton.icon(
                    onPressed: onPrev,
                    label: const Text('Previous'),
                    icon: const Icon(Icons.arrow_back, size: 16),
                  ),
                if (isBiweekly && onCurrent != null)
                  TextButton(
                    onPressed: onCurrent,
                    child: const Text('Current'),
                  ),
                if (onNext != null)
                  TextButton.icon(
                    onPressed: onNext,
                    label: const Text('Next'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                  ),
              ],
            ),
            if (period.to != null)
              Text(
                '${dateFmt.format(period.from)}–${dateFmt.format(period.to!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            // Summary stats row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _incomeLabel(period),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(period.income),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(period.expenses),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (period.net >= 0 ? '+' : '') + fmt.format(period.net),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositiveNet
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Scheduled items
            if (scheduledItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                'Scheduled',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ...scheduledItems.map((item) {
                final isIncome = item.type == TransactionType.income;
                final today = DateTime.now();
                final dayStart = DateTime(today.year, today.month, today.day);
                final itemDay = DateTime(
                  item.date.year,
                  item.date.month,
                  item.date.day,
                );
                final isPastUnpaid = !item.isPaid && itemDay.isBefore(dayStart);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          await vm.toggleOutlookItemPaid(item);
                          context.read<GoalsViewModel>().refresh();
                          context.read<GoalMilestonesViewModel>().refresh();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            item.isPaid
                                ? Icons.check_circle
                                : (isPastUnpaid
                                      ? Icons.error
                                      : Icons.radio_button_unchecked),
                            size: 20,
                            color: item.isPaid
                                ? AppColors.income
                                : (isPastUnpaid
                                      ? AppColors.expense
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFmt.format(item.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (isIncome ? '+' : '-') + fmt.format(item.amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                          if (item.isPaid) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Paid',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.income,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (noteItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ...noteItems.map((item) {
                final today = DateTime.now();
                final dayStart = DateTime(today.year, today.month, today.day);
                final itemDay = DateTime(
                  item.date.year,
                  item.date.month,
                  item.date.day,
                );
                final isPastUnpaid = !item.isPaid && itemDay.isBefore(dayStart);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          await vm.toggleOutlookItemPaid(item);
                          context.read<GoalsViewModel>().refresh();
                          context.read<GoalMilestonesViewModel>().refresh();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            item.isPaid
                                ? Icons.check_circle
                                : (isPastUnpaid
                                      ? Icons.error
                                      : Icons.radio_button_unchecked),
                            size: 20,
                            color: item.isPaid
                                ? AppColors.income
                                : (isPastUnpaid
                                      ? AppColors.expense
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFmt.format(item.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmt.format(item.amount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral,
                            ),
                          ),
                          if (item.isPaid) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Paid',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.income,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
