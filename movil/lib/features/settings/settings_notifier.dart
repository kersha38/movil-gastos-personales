import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/participantes_repository.dart';

class SettingsNotifier extends ChangeNotifier {
  static const _keyP1 = 'nombre_p1';
  static const _keyP2 = 'nombre_p2';
  static const _keyMiId = 'mi_participante_id';
  static const _keyThemeMode = 'theme_mode';

  final ParticipantesRepository _repo;

  SettingsNotifier({ParticipantesRepository? repo})
      : _repo = repo ?? ParticipantesRepository();

  String nombreP1 = 'Participante 1';
  String nombreP2 = 'Participante 2';
  // 'p1' | 'p2' | '' (no configurado)
  String miParticipanteId = '';
  ThemeMode themeMode = ThemeMode.system;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Carga caché local primero para respuesta instantánea
    nombreP1 = prefs.getString(_keyP1) ?? 'Participante 1';
    nombreP2 = prefs.getString(_keyP2) ?? 'Participante 2';
    miParticipanteId = prefs.getString(_keyMiId) ?? '';
    themeMode = _themeModeFromString(prefs.getString(_keyThemeMode));
    notifyListeners();

    // Luego sincroniza desde el backend
    try {
      final participantes = await _repo.getParticipantes();
      for (final p in participantes) {
        if (p.id == 'p1') nombreP1 = p.nombre;
        if (p.id == 'p2') nombreP2 = p.nombre;
      }
      await prefs.setString(_keyP1, nombreP1);
      await prefs.setString(_keyP2, nombreP2);
      notifyListeners();
    } catch (e) {
      developer.log('No se pudo cargar participantes del backend', name: 'SettingsNotifier', error: e);
    }
  }

  Future<void> guardar(String p1, String p2) async {
    final n1 = p1.trim().isEmpty ? 'Participante 1' : p1.trim();
    final n2 = p2.trim().isEmpty ? 'Participante 2' : p2.trim();

    // Actualiza backend y caché local en paralelo
    await Future.wait([
      _repo.actualizarParticipante('p1', n1),
      _repo.actualizarParticipante('p2', n2),
    ]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyP1, n1);
    await prefs.setString(_keyP2, n2);
    nombreP1 = n1;
    nombreP2 = n2;
    notifyListeners();
  }

  Future<void> guardarMiParticipante(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMiId, id);
    miParticipanteId = id;
    notifyListeners();
  }

  Future<void> cambiarTema(ThemeMode modo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, modo.name);
    themeMode = modo;
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
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
