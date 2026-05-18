import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/models/gasto.dart';
import '../../data/repositories/gastos_repository.dart';

class GastosNotifier extends ChangeNotifier {
  final GastosRepository _repo;

  GastosNotifier({GastosRepository? repo})
      : _repo = repo ?? GastosRepository();

  List<Gasto> gastos = [];
  bool isLoading = false;
  String? error;
  int selectedMes = DateTime.now().month;
  int selectedAnio = DateTime.now().year;

  Future<void> cargar() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      gastos = await _repo.getGastos(selectedMes, selectedAnio);
    } catch (e, s) {
      developer.log(
        'Error cargando gastos',
        name: 'GastosNotifier',
        error: e,
        stackTrace: s,
      );
      error = 'No se pudieron cargar los gastos. Intenta de nuevo.';
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
