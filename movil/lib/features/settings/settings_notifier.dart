import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  static const _keyP1 = 'nombre_p1';
  static const _keyP2 = 'nombre_p2';
  static const _keyMiId = 'mi_participante_id';

  String nombreP1 = 'Participante 1';
  String nombreP2 = 'Participante 2';
  // 'p1' | 'p2' | '' (no configurado)
  String miParticipanteId = '';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    nombreP1 = prefs.getString(_keyP1) ?? 'Participante 1';
    nombreP2 = prefs.getString(_keyP2) ?? 'Participante 2';
    miParticipanteId = prefs.getString(_keyMiId) ?? '';
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

  Future<void> guardarMiParticipante(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMiId, id);
    miParticipanteId = id;
    notifyListeners();
  }

  String get miNombre {
    if (miParticipanteId == 'p1') return nombreP1;
    if (miParticipanteId == 'p2') return nombreP2;
    return '';
  }

  String get otroParticipanteId {
    if (miParticipanteId == 'p1') return 'p2';
    if (miParticipanteId == 'p2') return 'p1';
    return '';
  }
}
