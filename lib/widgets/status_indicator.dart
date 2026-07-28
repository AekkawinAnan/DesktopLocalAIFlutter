import 'package:flutter/material.dart';
import '../services/ollama_process.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OllamaProcessService.isOllamaRunning(),
      builder: (context, snapshot) {
        final isRunning = snapshot.data ?? false;
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
                  color: isRunning ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isRunning ? 'Ollama' : 'Ollama (stopped)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}