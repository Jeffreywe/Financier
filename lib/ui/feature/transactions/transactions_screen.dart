import 'package:financier/domain/models/transaction.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/transactions/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransactionsViewModel>();
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateHeaderFmt = DateFormat('MMMM d, yyyy');

    final dateKeys = vm.sortedDateKeys;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [_FilterChip(current: vm.filterType, onChanged: vm.setFilter)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('transaction-add'),
        child: const Icon(Icons.add),
      ),
      body: vm.filtered.isEmpty
          ? _EmptyState(onAdd: () => context.pushNamed('transaction-add'))
          : CustomScrollView(
              slivers: [
                for (final dateKey in dateKeys) ...[
                  SliverToBoxAdapter(
                    child: _DateHeader(
                      date: dateKey,
                      transactions: vm.groupedByDate[dateKey]!,
                      formatter: dateHeaderFmt,
                      currencyFmt: currencyFmt,
                    ),
                  ),
                  SliverList.separated(
                    itemCount: vm.groupedByDate[dateKey]!.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (ctx, i) {
                      final tx = vm.groupedByDate[dateKey]![i];
                      return _TransactionTile(
                        transaction: tx,
                        categoryName: vm.categories
                            .where((c) => c.id == tx.categoryId)
                            .map((c) => c.name)
                            .firstOrNull,
                        currencyFmt: currencyFmt,
                        onEdit: () => ctx.pushNamed(
                          'transaction-edit',
                          pathParameters: {'id': tx.id},
                        ),
                        onDelete: () => _confirmDelete(ctx, vm, tx),
                      );
                    },
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionsViewModel vm,
    Transaction tx,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Remove "${tx.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              vm.deleteTransaction(tx.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final DateFormat formatter;
  final NumberFormat currencyFmt;

  const _DateHeader({
    required this.date,
    required this.transactions,
    required this.formatter,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final dayTotal = transactions.fold(
      0.0,
      (sum, t) =>
          sum +
          (t.type == TransactionType.income
              ? t.amount
              : t.type == TransactionType.expense
              ? -t.amount
              : 0),
    );
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formatter.format(date),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            (dayTotal >= 0 ? '+' : '') + currencyFmt.format(dayTotal),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: dayTotal >= 0 ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String? categoryName;
  final NumberFormat currencyFmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.categoryName,
    required this.currencyFmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final isNote = transaction.type == TransactionType.note;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? AppColors.income.withValues(alpha: 0.1)
            : isExpense
            ? AppColors.expense.withValues(alpha: 0.1)
            : AppColors.neutral.withValues(alpha: 0.1),
        child: Icon(
          isIncome
              ? Icons.arrow_downward
              : isExpense
              ? Icons.arrow_upward
              : Icons.sticky_note_2_outlined,
          color: isIncome
              ? AppColors.income
              : isExpense
              ? AppColors.expense
              : AppColors.neutral,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              transaction.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (transaction.isRecurring)
            const Icon(Icons.repeat, size: 14, color: AppColors.textSecondary),
        ],
      ),
      subtitle: Text(
        categoryName ?? 'Uncategorized',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isNote
                ? currencyFmt.format(transaction.amount)
                : (isIncome ? '+' : '-') +
                      currencyFmt.format(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isIncome
                  ? AppColors.income
                  : isExpense
                  ? AppColors.expense
                  : AppColors.neutral,
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

class _FilterChip extends StatelessWidget {
  final TransactionType? current;
  final ValueChanged<TransactionType?> onChanged;

  const _FilterChip({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButton<TransactionType?>(
        value: current,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list),
        items: const [
          DropdownMenuItem(value: null, child: Text('All')),
          DropdownMenuItem(
            value: TransactionType.income,
            child: Text('Income'),
          ),
          DropdownMenuItem(
            value: TransactionType.expense,
            child: Text('Expenses'),
          ),
          DropdownMenuItem(value: TransactionType.note, child: Text('Notes')),
        ],
        onChanged: onChanged,
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
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }
}
