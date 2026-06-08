import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://wud4c4eu2a.execute-api.us-east-1.amazonaws.com/prod';

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    developer.log('GET $uri', name: 'ApiClient');
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log('POST $uri', name: 'ApiClient');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log('PUT $uri', name: 'ApiClient');
    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    developer.log('DELETE $uri', name: 'ApiClient');
    final response = await _client.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
