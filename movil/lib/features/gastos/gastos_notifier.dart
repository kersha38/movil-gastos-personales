import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/models/gasto.dart';
import '../../data/models/transferencia.dart';
import '../../data/repositories/gastos_repository.dart';
import '../../data/repositories/transferencias_repository.dart';

class GastosNotifier extends ChangeNotifier {
  final GastosRepository _repo;
  final TransferenciasRepository _trRepo;

  GastosNotifier({GastosRepository? repo, TransferenciasRepository? trRepo})
      : _repo = repo ?? GastosRepository(),
        _trRepo = trRepo ?? TransferenciasRepository();

  List<Gasto> gastos = [];
  List<Transferencia> transferencias = [];
  bool isLoading = false;
  String? error;
  int selectedMes = DateTime.now().month;
  int selectedAnio = DateTime.now().year;

  Future<void> cargar() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final gastosResult = await _repo.getGastos(selectedMes, selectedAnio);
      gastos = gastosResult;
      // Transferencias es opcional — si el backend aún no tiene el endpoint no bloquea
      try {
        transferencias = await _trRepo.getTransferencias(selectedMes, selectedAnio);
      } catch (_) {
        transferencias = [];
      }
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

  Future<void> verificarGasto(
      String gastoId, bool verificado, String verificadoPor) async {
    await _repo.verificarGasto(gastoId, verificado, verificadoPor);
    final idx = gastos.indexWhere((g) => g.id == gastoId);
    if (idx != -1) {
      final g = gastos[idx];
      gastos[idx] = Gasto(
        id: g.id,
        monto: g.monto,
        descripcion: g.descripcion,
        categoriaId: g.categoriaId,
        categoriaNombre: g.categoriaNombre,
        pagadorId: g.pagadorId,
        pagadorNombre: g.pagadorNombre,
        participante1Id: g.participante1Id,
        participante1Nombre: g.participante1Nombre,
        participante2Id: g.participante2Id,
        participante2Nombre: g.participante2Nombre,
        esCompartido: g.esCompartido,
        porcentajeParticipante1: g.porcentajeParticipante1,
        porcentajeParticipante2: g.porcentajeParticipante2,
        esRecurrente: g.esRecurrente,
        perteneceAlSri: g.perteneceAlSri,
        timestamp: g.timestamp,
        verificado: verificado,
        verificadoPor: verificadoPor,
      );
      notifyListeners();
    }
  }

  Future<void> actualizarGasto(Gasto gasto) async {
    final actualizado = await _repo.actualizarGasto(gasto);
    final idx = gastos.indexWhere((g) => g.id == actualizado.id);
    if (idx != -1) {
      gastos[idx] = actualizado;
      notifyListeners();
    }
  }

  Future<void> crearTransferencia(Transferencia t) async {
    await _trRepo.crearTransferencia(t);
    await cargar();
  }

  Future<void> eliminarGasto(String id) async {
    await _repo.eliminarGasto(id);
    gastos.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> eliminarTransferencia(String id) async {
    await _trRepo.eliminarTransferencia(id);
    transferencias.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void cambiarMes(int delta) {
    final date = DateTime(selectedAnio, selectedMes + delta);
    selectedMes = date.month;
    selectedAnio = date.year;
    cargar();
  }
}
