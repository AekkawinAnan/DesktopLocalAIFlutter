import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class OllamaSystemService {
  static const _channel = MethodChannel('com.example.ollama_sidecar');

  static const _defaultHost = '127.0.0.1';
  static const _defaultPort = 11434;
  static Uri get _versionUri => Uri.parse('http://$_defaultHost:$_defaultPort/api/version');

  static Future<bool> isOllamaRunning() async {
    try {
      final client = http.Client();
      final response = await client.get(_versionUri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> installOllama() async {
    try {
      final result = await _channel.invokeMethod('installOllama');
      return result['success'] as bool? ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to install Ollama: ${e.message}');
    }
  }

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
