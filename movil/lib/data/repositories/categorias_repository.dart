import '../models/categoria.dart';
import '../services/api_client.dart';

class CategoriasRepository {
  final ApiClient _client;

  CategoriasRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<Categoria>> getCategorias() async {
    final data = await _client.get('/categorias') as List<dynamic>;
    return data
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Categoria> crearCategoria(String nombre) async {
    final data = await _client.post('/categorias', {
      'nombre': nombre,
      'esPredefinida': false,
    });
    return Categoria.fromJson(data as Map<String, dynamic>);
  }
}
