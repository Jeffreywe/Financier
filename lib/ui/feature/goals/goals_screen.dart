import 'package:financier/domain/models/savings_goal.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/goals/goals_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GoalsViewModel>();
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    if (vm.isLoading && vm.all.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Savings Goals')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('goal-add'),
        child: const Icon(Icons.add),
      ),
      body: vm.all.isEmpty
          ? _EmptyState(onAdd: () => context.pushNamed('goal-add'))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SummaryCard(
                    totalTarget: vm.totalTargetAmount,
                    totalCurrent: vm.totalCurrentAmount,
                    currencyFmt: currencyFmt,
                  ),
                ),
                if (vm.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: MaterialBanner(
                        content: Text(vm.error!),
                        leading: const Icon(Icons.error_outline),
                        actions: [
                          TextButton(
                            onPressed: () => ScaffoldMessenger.of(
                              context,
                            ).hideCurrentMaterialBanner(),
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverList.separated(
                  itemCount: vm.all.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _GoalCard(
                    goal: vm.all[i],
                    currencyFmt: currencyFmt,
                    onTap: () => ctx.pushNamed(
                      'goal-detail',
                      pathParameters: {'id': vm.all[i].id},
                    ),
                    onDelete: () => _confirmDelete(ctx, vm, vm.all[i]),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    GoalsViewModel vm,
    SavingsGoal goal,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Remove "${goal.name}" and all associated milestones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              vm.deleteGoal(goal.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalTarget;
  final double totalCurrent;
  final NumberFormat currencyFmt;

  const _SummaryCard({
    required this.totalTarget,
    required this.totalCurrent,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (totalTarget - totalCurrent).clamp(0.0, double.infinity);
    final percentComplete = totalTarget > 0
        ? (totalCurrent / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: AppColors.savings,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saved',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFmt.format(totalCurrent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentComplete,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percentComplete * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${currencyFmt.format(remaining)} remaining',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.currencyFmt,
    required this.onTap,
    required this.onDelete,
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

  String _getStatusLabel() {
    if (goal.isCompleted) {
      return 'Completed';
    }
    if (goal.isOverdue) {
      return 'Overdue';
    }
    if (goal.daysUntilDue <= 0) {
      return 'Due Soon';
    }
    return goal.statusLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${goal.daysUntilDue} days until ${DateFormat('MMM d, yyyy').format(goal.dueDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        _getStatusLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.percentComplete,
                    minHeight: 10,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFmt.format(goal.currentAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFmt.format(goal.targetAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFmt.format(goal.remainingAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Progress',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(goal.percentComplete * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Savings Goals Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first goal to start tracking\nyour savings progress.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }
}
