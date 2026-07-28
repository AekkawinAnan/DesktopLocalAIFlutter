import 'package:flutter/services.dart';

class OllamaProcessService {
  static const _channel = MethodChannel('com.example.ollama_sidecar');

  static Future<bool> startOllama() async {
    try {
      final result = await _channel.invokeMethod('startOllama');
      return result['success'] as bool? ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to start Ollama: ${e.message}');
    }
  }

  static Future<bool> stopOllama() async {
    try {
      final result = await _channel.invokeMethod('stopOllama');
      return result['success'] as bool? ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to stop Ollama: ${e.message}');
    }
  }

  static Future<bool> isOllamaRunning() async {
    try {
      final result = await _channel.invokeMethod('isOllamaRunning');
      return result['running'] as bool? ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to check Ollama status: ${e.message}');
    }
  }

  static Future<String> getOllamaLogs() async {
    try {
      final result = await _channel.invokeMethod('getOllamaLogs');
      return result['logs'] as String? ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get logs: ${e.message}');
    }
  }

  static Future<String> getOllamaVersion() async {
    try {
      final result = await _channel.invokeMethod('getOllamaVersion');
      return result['version'] as String? ?? 'unknown';
    } on PlatformException catch (e) {
      throw Exception('Failed to get version: ${e.message}');
    }
  }

  static Future<String> getOllamaBinaryPath() async {
    try {
      final result = await _channel.invokeMethod('getOllamaBinaryPath');
      return result['path'] as String? ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get binary path: ${e.message}');
    }
  }

  static Future<String> getModelsDirectory() async {
    try {
      final result = await _channel.invokeMethod('getModelsDirectory');
      return result['path'] as String? ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to get models directory: ${e.message}');
    }
  }
}