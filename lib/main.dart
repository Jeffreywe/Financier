import 'package:financier/di/app_providers.dart';
import 'package:financier/routing/app_router.dart';
import 'package:financier/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final providers = await buildProviders();
  runApp(FinancierApp(providers: providers));
}

class FinancierApp extends StatelessWidget {
  final List<SingleChildWidget> providers;

  const FinancierApp({super.key, required this.providers});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp.router(
        title: 'Financier',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
