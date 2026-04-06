import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categoria.dart';
import '../models/participante.dart';
import '../models/gasto.dart';

class ApiService {
  static const String _baseUrl = 'https://api.example.com'; // TODO: reemplazar con URL real

  // --- Categorías ---

  Future<List<Categoria>> getCategorias() async {
    final response = await http.get(Uri.parse('$_baseUrl/categorias'));
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Categoria.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Categoria> crearCategoria(String nombre) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/categorias'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'esPredefinida': false}),
    );
    _checkStatus(response);
    return Categoria.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // --- Participantes ---

  Future<List<Participante>> getParticipantes() async {
    final response = await http.get(Uri.parse('$_baseUrl/participantes'));
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Participante.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Gastos ---

  Future<List<Gasto>> getGastos() async {
    final response = await http.get(Uri.parse('$_baseUrl/gastos'));
    _checkStatus(response);
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Gasto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Gasto> crearGasto(Gasto gasto) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/gastos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(gasto.toJson()),
    );
    _checkStatus(response);
    return Gasto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}
