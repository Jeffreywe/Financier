import 'package:financier/ui/feature/accounts/accounts_screen.dart';
import 'package:financier/ui/feature/accounts/add_edit_account_screen.dart';
import 'package:financier/ui/feature/budget/budget_screen.dart';
import 'package:financier/ui/feature/data_port/data_port_screen.dart';
import 'package:financier/ui/feature/dashboard/dashboard_screen.dart';
import 'package:financier/ui/feature/debt/add_edit_debt_screen.dart';
import 'package:financier/ui/feature/debt/debt_detail_screen.dart';
import 'package:financier/ui/feature/debt/debt_screen.dart';
import 'package:financier/ui/feature/transactions/add_edit_transaction_screen.dart';
import 'package:financier/ui/feature/transactions/transactions_screen.dart';
import 'package:financier/ui/core/widgets/root_scaffold.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => RootScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, _) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'data-port',
                  name: 'data-port',
                  builder: (context, state) => const DataPortScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounts',
              name: 'accounts',
              builder: (context, _) => const AccountsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'account-add',
                  builder: (context, _) => const AddEditAccountScreen(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: 'account-edit',
                  builder: (_, state) => AddEditAccountScreen(
                    accountId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              name: 'transactions',
              builder: (context, state) => const TransactionsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'transaction-add',
                  builder: (context, state) => const AddEditTransactionScreen(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: 'transaction-edit',
                  builder: (context, state) => AddEditTransactionScreen(
                    transactionId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budget',
              name: 'budget',
              builder: (context, state) => const BudgetScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/debt',
              name: 'debt',
              builder: (context, state) => const DebtScreen(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  name: 'debt-detail',
                  builder: (context, state) =>
                      DebtDetailScreen(debtId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'add',
                  name: 'debt-add',
                  builder: (context, state) => const AddEditDebtScreen(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: 'debt-edit',
                  builder: (context, state) =>
                      AddEditDebtScreen(debtId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
