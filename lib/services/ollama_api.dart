import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to list models: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    final models = data['models'] as List;
    return models.map((m) => OllamaModel.fromJson(m)).toList();
  }

  Future<void> pullModel(String modelName, {Function(int)? onProgress}) async {
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/api/pull'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'name': modelName, 'stream': true});

      final response = await client.send(request).timeout(const Duration(minutes: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to pull model: ${response.statusCode}');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            if (data['total'] != null && data['completed'] != null && onProgress != null) {
              final completed = data['completed'] as int;
              onProgress(completed);
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  Future<String> getVersion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/version'),
    ).timeout(const Duration(seconds: 5));
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
    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/chat'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': stream,
    });

    final response = await client.send(request);

    if (response.statusCode != 200) {
      debugPrint('OllamaApi: chat status=${response.statusCode}');
      client.close();
      throw Exception('Chat request failed: ${response.statusCode}');
    }

    debugPrint('OllamaApi: chat status=${response.statusCode} streaming response');
    try {
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            debugPrint('OllamaApi: line=${data['done'] == true ? "done" : data['message']?['content'] ?? line}');
            if (data['done'] == true) {
              yield {'done': true, 'message': data['message'] ?? {}};
              return;
            }
            yield {'done': false, 'message': data['message'] ?? {}};
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  Stream<Map<String, dynamic>> generateStream({
    required String model,
    required String prompt,
    bool stream = true,
  }) async* {
    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/generate'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': model,
      'prompt': prompt,
      'stream': stream,
    });

    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception('Generate request failed: ${response.statusCode}');
    }

    try {
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            if (data['done'] == true) {
              yield {'done': true, 'response': data['response']};
              return;
            }
            yield {'done': false, 'response': data['response']};
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> deleteModel(String modelName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName}),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete model: ${response.statusCode}');
    }
  }
}