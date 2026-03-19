import 'package:financier/domain/models/budget_category.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/budget/budget_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final monthFmt = DateFormat('MMMM yyyy');
    final buckets = vm.bucketSummaries;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget'), centerTitle: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _MonthHeader(
              month: vm.selectedMonth,
              monthFmt: monthFmt,
              onPrev: vm.previousMonth,
              onNext: vm.nextMonth,
            ),
          ),
          SliverToBoxAdapter(
            child: _LeftToBudgetCard(
              leftToBudget: vm.leftToBudget,
              income: vm.monthlyIncome,
              expenses: vm.monthlyExpenses,
              currencyFmt: currencyFmt,
            ),
          ),
          SliverList.separated(
            itemCount: buckets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, i) =>
                _BucketCard(summary: buckets[i], currencyFmt: currencyFmt),
          ),
          if (vm.monthlyIncome == 0)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: _NoIncomeHint(),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final DateFormat monthFmt;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.monthFmt,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(
            monthFmt.format(month),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _LeftToBudgetCard extends StatelessWidget {
  final double leftToBudget;
  final double income;
  final double expenses;
  final NumberFormat currencyFmt;

  const _LeftToBudgetCard({
    required this.leftToBudget,
    required this.income,
    required this.expenses,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = leftToBudget >= 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPositive
            ? AppColors.primaryContainer
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Left to Budget',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFmt.format(leftToBudget),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.income : AppColors.expense,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'Income',
                value: currencyFmt.format(income),
                color: AppColors.income,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Expenses',
                value: currencyFmt.format(expenses),
                color: AppColors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BucketCard extends StatefulWidget {
  final BucketSummary summary;
  final NumberFormat currencyFmt;

  const _BucketCard({required this.summary, required this.currencyFmt});

  @override
  State<_BucketCard> createState() => _BucketCardState();
}

class _BucketCardState extends State<_BucketCard> {
  bool _expanded = false;

  Color get _bucketColor {
    switch (widget.summary.bucket) {
      case BudgetBucket.needs:
        return AppColors.needs;
      case BudgetBucket.wants:
        return AppColors.wants;
      case BudgetBucket.savings:
        return AppColors.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final fmt = widget.currencyFmt;
    final overBudget = s.actual > s.target && s.target > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.percentUsed,
                      backgroundColor: AppColors.divider,
                      color: overBudget ? AppColors.expense : _bucketColor,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${fmt.format(s.actual)} spent',
                        style: TextStyle(
                          fontSize: 13,
                          color: overBudget
                              ? AppColors.expense
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        s.target > 0
                            ? '${fmt.format(s.remaining)} of ${fmt.format(s.target)}'
                            : 'No income entered',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && s.categories.isNotEmpty) ...[
            const Divider(height: 1),
            ...s.categories.map(
              (cat) => ListTile(
                dense: true,
                title: Text(
                  cat.categoryName,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Text(
                  fmt.format(cat.actual),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          if (_expanded && s.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No spending in this bucket this month.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoIncomeHint extends StatelessWidget {
  const _NoIncomeHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.info_outline, size: 40, color: AppColors.textDisabled),
        const SizedBox(height: 12),
        const Text(
          'Add an income transaction this month to see your 50/30/20 budget targets.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}
