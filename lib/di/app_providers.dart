import 'package:financier/data/repositories/accounts_repository.dart';
import 'package:financier/data/repositories/categories_repository.dart';
import 'package:financier/data/repositories/debt_repository.dart';
import 'package:financier/data/repositories/transactions_repository.dart';
import 'package:financier/data/services/data_port_service.dart';
import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/ui/feature/accounts/accounts_view_model.dart';
import 'package:financier/ui/feature/budget/budget_view_model.dart';
import 'package:financier/ui/feature/data_port/data_port_view_model.dart';
import 'package:financier/ui/feature/dashboard/dashboard_view_model.dart';
import 'package:financier/ui/feature/debt/debt_view_model.dart';
import 'package:financier/ui/feature/transactions/transactions_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<SingleChildWidget>> buildProviders() async {
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);

  final accountsRepo = AccountsRepository(storage);
  final transactionsRepo = TransactionsRepository(storage);
  final debtRepo = DebtRepository(storage);
  final categoriesRepo = CategoriesRepository(storage);
  final dataPortService = DataPortService(
    storage,
    accountsRepo,
    transactionsRepo,
    debtRepo,
    categoriesRepo,
  );

  return [
    Provider<LocalStorageService>.value(value: storage),
    Provider<AccountsRepository>.value(value: accountsRepo),
    Provider<TransactionsRepository>.value(value: transactionsRepo),
    Provider<DebtRepository>.value(value: debtRepo),
    Provider<CategoriesRepository>.value(value: categoriesRepo),
    Provider<DataPortService>.value(value: dataPortService),
    ChangeNotifierProvider<AccountsViewModel>(
      create: (_) => AccountsViewModel(accountsRepo),
    ),
    ChangeNotifierProvider<TransactionsViewModel>(
      create: (_) => TransactionsViewModel(transactionsRepo, categoriesRepo),
    ),
    ChangeNotifierProvider<BudgetViewModel>(
      create: (_) => BudgetViewModel(transactionsRepo, categoriesRepo),
    ),
    ChangeNotifierProvider<DebtViewModel>(
      create: (_) => DebtViewModel(debtRepo, transactionsRepo),
    ),
    ChangeNotifierProvider<DashboardViewModel>(
      create: (_) =>
          DashboardViewModel(transactionsRepo, accountsRepo, debtRepo),
    ),
    ChangeNotifierProvider<DataPortViewModel>(
      create: (_) => DataPortViewModel(dataPortService),
    ),
  ];
}
