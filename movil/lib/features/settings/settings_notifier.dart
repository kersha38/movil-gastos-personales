import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  static const _keyP1 = 'nombre_p1';
  static const _keyP2 = 'nombre_p2';

  String nombreP1 = 'Participante 1';
  String nombreP2 = 'Participante 2';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    nombreP1 = prefs.getString(_keyP1) ?? 'Participante 1';
    nombreP2 = prefs.getString(_keyP2) ?? 'Participante 2';
    notifyListeners();
  }

  Future<void> guardar(String p1, String p2) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyP1, p1.trim().isEmpty ? 'Participante 1' : p1.trim());
    await prefs.setString(_keyP2, p2.trim().isEmpty ? 'Participante 2' : p2.trim());
    nombreP1 = prefs.getString(_keyP1)!;
    nombreP2 = prefs.getString(_keyP2)!;
    notifyListeners();
  }
}
