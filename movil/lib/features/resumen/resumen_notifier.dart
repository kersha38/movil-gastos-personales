import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/models/resumen.dart';
import '../../data/repositories/resumen_repository.dart';

class ResumenNotifier extends ChangeNotifier {
  final ResumenRepository _repo;

  ResumenNotifier({ResumenRepository? repo})
      : _repo = repo ?? ResumenRepository();

  Resumen? resumen;
  bool isLoading = false;
  String? error;
  int selectedMes = DateTime.now().month;
  int selectedAnio = DateTime.now().year;

  Future<void> cargar() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      resumen = await _repo.getResumen(selectedMes, selectedAnio);
    } catch (e, s) {
      developer.log(
        'Error cargando resumen',
        name: 'ResumenNotifier',
        error: e,
        stackTrace: s,
      );
      error = 'No se pudo cargar el resumen. Intenta de nuevo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void cambiarMes(int delta) {
    final date = DateTime(selectedAnio, selectedMes + delta);
    selectedMes = date.month;
    selectedAnio = date.year;
    cargar();
  }
}
