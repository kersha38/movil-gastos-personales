import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/gastos/gasto_form_page.dart';
import 'features/gastos/gastos_notifier.dart';
import 'features/gastos/gastos_page.dart';
import 'features/graficos/graficos_notifier.dart';
import 'features/graficos/graficos_page.dart';
import 'features/pagos_mensuales/pagos_mensuales_notifier.dart';
import 'features/pagos_mensuales/pagos_mensuales_page.dart';
import 'features/resumen/resumen_notifier.dart';
import 'features/resumen/resumen_page.dart';
import 'features/settings/settings_notifier.dart';
import 'features/settings/settings_page.dart';

class App extends StatefulWidget {
  final SettingsNotifier settingsNotifier;
  final GastosNotifier gastosNotifier;
  final ResumenNotifier resumenNotifier;
  final GraficosNotifier graficosNotifier;
  final PagosMensualesNotifier pagosMensualesNotifier;

  const App({
    super.key,
    required this.settingsNotifier,
    required this.gastosNotifier,
    required this.resumenNotifier,
    required this.graficosNotifier,
    required this.pagosMensualesNotifier,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => _MainScaffold(
            shell: shell,
            settingsNotifier: widget.settingsNotifier,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => ResumenPage(
                    notifier: widget.resumenNotifier,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/gastos',
                  builder: (_, _) => GastosPage(
                    notifier: widget.gastosNotifier,
                    settingsNotifier: widget.settingsNotifier,
                  ),
                  routes: [
                    GoRoute(
                      path: 'nuevo',
                      builder: (_, state) => GastoFormPage(
                        settingsNotifier:
                            state.extra as SettingsNotifier? ??
                            widget.settingsNotifier,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/graficos',
                  builder: (_, _) => GraficosPage(
                    notifier: widget.graficosNotifier,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/pagos-mensuales',
                  builder: (_, _) => PagosMensualesPage(
                    notifier: widget.pagosMensualesNotifier,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) =>
              SettingsPage(notifier: widget.settingsNotifier),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gastos Personales',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class _MainScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  final SettingsNotifier settingsNotifier;

  const _MainScaffold({
    required this.shell,
    required this.settingsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Gastos',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Gráficos',
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            selectedIcon: Icon(Icons.repeat),
            label: 'Mensuales',
          ),
        ],
      ),
    );
  }
}
