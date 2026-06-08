import '../models/transferencia.dart';
import '../services/api_client.dart';

class TransferenciasRepository {
  final ApiClient _client;

  TransferenciasRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Transferencia>> getTransferencias(int mes, int anio) async {
    final data = await _client.get('/transferencias', queryParams: {
      'mes': mes.toString(),
      'anio': anio.toString(),
    }) as List<dynamic>;
    return data
        .map((e) => Transferencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Transferencia> crearTransferencia(Transferencia t) async {
    final data = await _client.post('/transferencias', t.toJson());
    return Transferencia.fromJson(data as Map<String, dynamic>);
  }

  Future<void> eliminarTransferencia(String id) async {
    await _client.delete('/transferencias/$id');
  }
}
