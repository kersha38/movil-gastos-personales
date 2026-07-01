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
  Set<String> categoriasFiltro = {};

  List<ResumenCategoria> get categoriasDisponibles =>
      resumen?.gastosPorCategoria ?? [];

  bool get filtroActivo => categoriasFiltro.isNotEmpty;

  double get totalFiltrado {
    if (resumen == null) return 0;
    if (categoriasFiltro.isEmpty) return resumen!.totalMes;
    return resumen!.gastosPorCategoria
        .where((c) => categoriasFiltro.contains(c.categoriaId))
        .fold(0.0, (sum, c) => sum + c.total);
  }

  Future<void> cargar() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      resumen = await _repo.getResumen(selectedMes, selectedAnio);
      // Si el filtro activo ya no tiene categorías válidas, limpiarlo
      if (categoriasFiltro.isNotEmpty) {
        final ids = resumen!.gastosPorCategoria.map((c) => c.categoriaId).toSet();
        categoriasFiltro = categoriasFiltro.intersection(ids);
      }
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
    categoriasFiltro.clear();
    cargar();
  }

  void toggleCategoria(String id) {
    if (categoriasFiltro.contains(id)) {
      categoriasFiltro.remove(id);
    } else {
      categoriasFiltro.add(id);
    }
    notifyListeners();
  }

  void aplicarFiltro(Set<String> ids) {
    categoriasFiltro = ids;
    notifyListeners();
  }

  void limpiarFiltro() {
    categoriasFiltro.clear();
    notifyListeners();
  }
}
