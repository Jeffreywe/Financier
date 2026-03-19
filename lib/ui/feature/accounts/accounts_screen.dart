import 'package:financier/domain/models/account.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountsViewModel>();
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('account-add'),
        child: const Icon(Icons.add),
      ),
      body: vm.accounts.isEmpty
          ? _EmptyState(onAdd: () => context.pushNamed('account-add'))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _TotalCard(
                    total: vm.totalBalance,
                    currencyFmt: currencyFmt,
                  ),
                ),
                SliverList.separated(
                  itemCount: vm.accounts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) => _AccountTile(
                    account: vm.accounts[i],
                    currencyFmt: currencyFmt,
                    onEdit: () => ctx.pushNamed(
                      'account-edit',
                      pathParameters: {'id': vm.accounts[i].id},
                    ),
                    onDelete: () => _confirmDelete(ctx, vm, vm.accounts[i]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Savings Goals'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.savings,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => context.pushNamed('goals'),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AccountsViewModel vm,
    Account account,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Remove "${account.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.deleteAccount(account.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final NumberFormat currencyFmt;

  const _TotalCard({required this.total, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFmt.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final NumberFormat currencyFmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountTile({
    required this.account,
    required this.currencyFmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = account.balance < 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        child: Icon(_iconForType(account.type), color: AppColors.primary),
      ),
      title: Text(
        account.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        account.typeLabel,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            currencyFmt.format(account.balance),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isNegative ? AppColors.expense : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
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

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.credit:
        return Icons.credit_card;
      case AccountType.cash:
        return Icons.payments;
      case AccountType.other:
        return Icons.wallet;
    }
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          const Text(
            'No accounts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first account to get started',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }
}
