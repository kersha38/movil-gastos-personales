import 'package:flutter/material.dart';

import 'app.dart';
import 'features/gastos/gastos_notifier.dart';
import 'features/graficos/graficos_notifier.dart';
import 'features/pagos_mensuales/pagos_mensuales_notifier.dart';
import 'features/resumen/resumen_notifier.dart';
import 'features/settings/settings_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsNotifier = SettingsNotifier();
  final gastosNotifier = GastosNotifier();
  final resumenNotifier = ResumenNotifier();
  final graficosNotifier = GraficosNotifier();
  final pagosMensualesNotifier = PagosMensualesNotifier();
  await settingsNotifier.init();
  runApp(
    App(
      settingsNotifier: settingsNotifier,
      gastosNotifier: gastosNotifier,
      resumenNotifier: resumenNotifier,
      graficosNotifier: graficosNotifier,
      pagosMensualesNotifier: pagosMensualesNotifier,
    ),
  );
}
