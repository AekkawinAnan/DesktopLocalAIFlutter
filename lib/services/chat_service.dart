import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ollama_sidecar_app/models/message.dart';
import 'package:ollama_sidecar_app/services/ollama_api.dart';
import 'package:uuid/uuid.dart';

class ChatService extends ChangeNotifier {
  final OllamaApi _api = OllamaApi();
  final Uuid _uuid = const Uuid();

  final List<Message> _messages = [];
  String _currentModel = '';
  bool _isStreaming = false;
  final StreamController<String> _streamController = StreamController<String>.broadcast();

  List<Message> get messages => List.unmodifiable(_messages);
  String get currentModel => _currentModel;
  bool get isStreaming => _isStreaming;
  Stream<String> get stream => _streamController.stream;

  Future<void> sendMessage(String userMessage, {String model = 'llama3'}) async {
    if (_isStreaming) return;

    _currentModel = model;
    _isStreaming = true;
    notifyListeners();

    final userMsg = Message(
      id: _uuid.v4(),
      role: 'user',
      content: userMessage,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    Timer? _streamTimer;
    String _pendingStreamContent = '';

    void _scheduleStreamFlush() {
      _streamTimer?.cancel();
      _streamTimer = Timer(const Duration(milliseconds: 32), () {
        if (_pendingStreamContent.isNotEmpty && !_streamController.isClosed) {
          _streamController.add(_pendingStreamContent);
          _pendingStreamContent = '';
        }
      });
    }

    try {
      final stream = _api.chatStream(
        model: model,
        messages: _messages.map((m) => {
          'role': m.role,
          'content': m.content,
        }).toList(),
      );

      String assistantContent = '';
      final assistantId = _uuid.v4();

      await for (final chunk in stream) {
        if (chunk['done'] == true) {
          _streamTimer?.cancel();
          if (_pendingStreamContent.isNotEmpty && !_streamController.isClosed) {
            _streamController.add(_pendingStreamContent);
            _pendingStreamContent = '';
          }
          final assistantMsg = Message(
            id: assistantId,
            role: 'assistant',
            content: assistantContent,
            createdAt: DateTime.now(),
          );
          _messages.add(assistantMsg);
          notifyListeners();
          break;
        }

        final message = chunk['message'];
        if (message != null && message['content'] != null) {
          final content = message['content'] as String;
          assistantContent += content;
          _pendingStreamContent += content;
          _scheduleStreamFlush();
        }
      }
    } catch (e) {
      _streamController.addError(e);
    } finally {
      _streamTimer?.cancel();
      _isStreaming = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _currentModel = '';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _streamController.close();
  }
}