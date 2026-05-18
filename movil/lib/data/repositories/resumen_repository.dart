import '../models/resumen.dart';
import '../services/api_client.dart';

class ResumenRepository {
  final ApiClient _client;

  ResumenRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Resumen> getResumen(int mes, int anio) async {
    final data = await _client.get('/resumen', queryParams: {
      'mes': mes.toString(),
      'anio': anio.toString(),
    });
    return Resumen.fromJson(data as Map<String, dynamic>);
  }
}
