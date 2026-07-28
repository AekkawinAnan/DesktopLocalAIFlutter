import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ollama_sidecar_app/services/ollama_process.dart';

class StatusIndicator extends StatefulWidget {
  const StatusIndicator({super.key});

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkOllamaStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _checkOllamaStatus());
  }

  Future<void> _checkOllamaStatus() async {
    try {
      final running = await OllamaSystemService.isOllamaRunning();
      if (mounted) {
        setState(() => _isRunning = running);
      }
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRunning ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isRunning ? 'Ollama' : 'Ollama (stopped)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
