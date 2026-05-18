import 'package:flutter/material.dart';

import 'app.dart';
import 'features/gastos/gastos_notifier.dart';
import 'features/resumen/resumen_notifier.dart';
import 'features/settings/settings_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsNotifier = SettingsNotifier();
  final gastosNotifier = GastosNotifier();
  final resumenNotifier = ResumenNotifier();
  await settingsNotifier.init();
  runApp(
    App(
      settingsNotifier: settingsNotifier,
      gastosNotifier: gastosNotifier,
      resumenNotifier: resumenNotifier,
    ),
  );
}
