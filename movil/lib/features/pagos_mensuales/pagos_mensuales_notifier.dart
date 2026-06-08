import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/models/gasto_mensual.dart';
import '../../data/repositories/gastos_mensuales_repository.dart';

class PagosMensualesNotifier extends ChangeNotifier {
  final GastosMensualesRepository _repo;

  PagosMensualesNotifier({GastosMensualesRepository? repo})
      : _repo = repo ?? GastosMensualesRepository();

  List<GastoMensual> plantillas = [];
  Map<String, List<GastoMensual>> instanciasPorPlantilla = {};
  bool isLoading = false;
  String? error;

  Future<void> cargar() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      plantillas = await _repo.getPlantillas();
    } catch (e, s) {
      developer.log(
        'Error cargando pagos mensuales',
        name: 'PagosMensualesNotifier',
        error: e,
        stackTrace: s,
      );
      error = 'No se pudieron cargar los pagos mensuales.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarInstancias(String plantillaId) async {
    try {
      final items = await _repo.getInstancias(plantillaId);
      instanciasPorPlantilla[plantillaId] = items;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error cargando instancias',
        name: 'PagosMensualesNotifier',
        error: e,
      );
    }
  }

  Future<GastoMensual> crearPlantilla(GastoMensual gm) async {
    final nueva = await _repo.crearPlantilla(gm);
    plantillas.add(nueva);
    notifyListeners();
    return nueva;
  }

  Future<GastoMensual> actualizarPlantilla(GastoMensual gm) async {
    final actualizada = await _repo.actualizarPlantilla(gm);
    final idx = plantillas.indexWhere((p) => p.id == gm.id);
    if (idx != -1) plantillas[idx] = actualizada;
    notifyListeners();
    return actualizada;
  }

  Future<void> eliminarPlantilla(String id) async {
    await _repo.eliminar(id);
    plantillas.removeWhere((p) => p.id == id);
    instanciasPorPlantilla.remove(id);
    notifyListeners();
  }

  Future<void> eliminarInstancia(String plantillaId, String instanciaId) async {
    await _repo.eliminar(instanciaId);
    instanciasPorPlantilla[plantillaId]
        ?.removeWhere((i) => i.id == instanciaId);
    notifyListeners();
  }

  Future<GastoMensual> actualizarInstancia(GastoMensual gm) async {
    final actualizada = await _repo.actualizarPlantilla(gm);
    final lista = instanciasPorPlantilla[gm.plantillaId];
    if (lista != null) {
      final idx = lista.indexWhere((i) => i.id == gm.id);
      if (idx != -1) lista[idx] = actualizada;
    }
    notifyListeners();
    return actualizada;
  }
}
