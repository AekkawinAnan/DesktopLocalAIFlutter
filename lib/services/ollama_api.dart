import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ollama_model.dart';

class OllamaApi {
  static final OllamaApi _instance = OllamaApi._internal();
  factory OllamaApi() => _instance;
  OllamaApi._internal();

  String baseUrl = 'http://127.0.0.1:11434';

  bool _connected = false;

  bool get isConnected => _connected;

  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/version'),
      ).timeout(const Duration(seconds: 5));
      _connected = response.statusCode == 200;
      return _connected;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  Future<List<OllamaModel>> listModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tags'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to list models: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    final models = data['models'] as List;
    return models.map((m) => OllamaModel.fromJson(m)).toList();
  }

  Future<void> pullModel(String modelName, {Function(int)? onProgress}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pull'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName, 'stream': true}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to pull model: ${response.statusCode}');
    }

    final lines = response.body.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final data = jsonDecode(line);
        if (data['total'] != null && data['completed'] != null && onProgress != null) {
          final completed = data['completed'] as int;
          onProgress(completed);
        }
      } catch (_) {
        continue;
      }
    }
  }

  Future<String> getVersion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/version'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get version: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    return data['version'] as String? ?? 'unknown';
  }

  Stream<Map<String, dynamic>> chatStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    bool stream = true,
  }) async* {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'stream': stream,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Chat request failed: ${response.statusCode}');
    }

    final lines = response.body.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final data = jsonDecode(line);
        if (data['done'] == true) {
          yield {'done': true, 'message': data['message']};
          return;
        }
        yield {'done': false, 'message': data['message']};
      } catch (_) {
        continue;
      }
    }
  }

  Stream<Map<String, dynamic>> generateStream({
    required String model,
    required String prompt,
    bool stream = true,
  }) async* {
    final response = await http.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': stream,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Generate request failed: ${response.statusCode}');
    }

    final lines = response.body.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final data = jsonDecode(line);
        if (data['done'] == true) {
          yield {'done': true, 'response': data['response']};
          return;
        }
        yield {'done': false, 'response': data['response']};
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> deleteModel(String modelName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete model: ${response.statusCode}');
    }
  }
}