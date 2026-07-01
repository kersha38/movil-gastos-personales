import '../models/gasto.dart';
import '../services/api_client.dart';

class GastosRepository {
  final ApiClient _client;

  GastosRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Gasto>> getGastos(int mes, int anio) async {
    final data = await _client.get('/gastos', queryParams: {
      'mes': mes.toString(),
      'anio': anio.toString(),
    }) as List<dynamic>;
    return data
        .map((e) => Gasto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Gasto> crearGasto(Gasto gasto) async {
    final data = await _client.post('/gastos', gasto.toJson());
    return Gasto.fromJson(data as Map<String, dynamic>);
  }

  Future<Gasto> actualizarGasto(Gasto gasto) async {
    final data = await _client.put('/gastos/${gasto.id}', gasto.toJson());
    return Gasto.fromJson(data as Map<String, dynamic>);
  }

  Future<void> verificarGasto(
      String gastoId, bool verificado, String verificadoPor) async {
    await _client.put('/gastos/$gastoId/verificar', {
      'verificado': verificado,
      'verificadoPor': verificadoPor,
    });
  }

  Future<void> eliminarGasto(String id) async {
    await _client.delete('/gastos/$id');
  }
}
