import '../models/participante.dart';
import '../services/api_client.dart';

class ParticipantesRepository {
  final ApiClient _client;

  ParticipantesRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  Future<List<Participante>> getParticipantes() async {
    final data = await _client.get('/participantes') as List<dynamic>;
    return data
        .map((e) => Participante.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Participante> actualizarParticipante(
    String id,
    String nombre,
  ) async {
    final data = await _client.put('/participantes/$id', {'nombre': nombre});
    return Participante.fromJson(data as Map<String, dynamic>);
  }
}
