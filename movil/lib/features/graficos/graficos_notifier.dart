import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/models/resumen.dart';
import '../../data/repositories/resumen_repository.dart';

class GraficosNotifier extends ChangeNotifier {
  final ResumenRepository _repo;

  GraficosNotifier({ResumenRepository? repo})
      : _repo = repo ?? ResumenRepository();

  List<ResumenCategoria> categorias = [];
  bool isLoading = false;
  String? error;
  int selectedMes = DateTime.now().month;
  int selectedAnio = DateTime.now().year;

  Future<void> cargar() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final resumen = await _repo.getResumen(selectedMes, selectedAnio);
      categorias = resumen.gastosPorCategoria;
    } catch (e, s) {
      developer.log(
        'Error cargando gráficos',
        name: 'GraficosNotifier',
        error: e,
        stackTrace: s,
      );
      error = 'No se pudieron cargar los gráficos. Intenta de nuevo.';
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
