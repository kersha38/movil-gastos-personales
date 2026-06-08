import '../models/gasto_mensual.dart';
import '../services/api_client.dart';

class GastosMensualesRepository {
  final ApiClient _client;

  GastosMensualesRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  Future<List<GastoMensual>> getPlantillas() async {
    final data = await _client.get('/gastos-mensuales',
        queryParams: {'tipo': 'plantilla'}) as List<dynamic>;
    return data
        .map((e) => GastoMensual.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GastoMensual>> getInstancias(String plantillaId) async {
    final data = await _client.get('/gastos-mensuales',
        queryParams: {'plantillaId': plantillaId}) as List<dynamic>;
    return data
        .map((e) => GastoMensual.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GastoMensual> crearPlantilla(GastoMensual gm) async {
    final data = await _client.post('/gastos-mensuales', gm.toJson());
    return GastoMensual.fromJson(data as Map<String, dynamic>);
  }

  Future<GastoMensual> actualizarPlantilla(GastoMensual gm) async {
    final data = await _client.put('/gastos-mensuales/${gm.id}', gm.toJson());
    return GastoMensual.fromJson(data as Map<String, dynamic>);
  }

  Future<void> eliminar(String id) async {
    await _client.delete('/gastos-mensuales/$id');
  }
}
