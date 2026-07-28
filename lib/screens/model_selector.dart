import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ollama_model.dart';
import '../services/ollama_api.dart';
import '../services/chat_service.dart';
import '../widgets/status_indicator.dart';

class ModelSelector extends StatefulWidget {
  const ModelSelector({super.key});

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  List<OllamaModel> _models = [];
  bool _isLoading = false;
  String _pullingModel = '';
  int _pullProgress = 0;
  final TextEditingController _pullController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _pullController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await OllamaApi().checkConnection();
      if (!isConnected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ollama server is not running. Please start it first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final models = await OllamaApi().listModels();
      setState(() => _models = models);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load models: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pullModel(String modelName) async {
    final trimmed = modelName.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _pullingModel = trimmed;
      _pullProgress = 0;
    });

    try {
      await OllamaApi().pullModel(
        trimmed,
        onProgress: (completed) {
          if (mounted) {
            setState(() => _pullProgress = completed);
          }
        },
      );
      _pullController.clear();
      await _loadModels();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model "$trimmed" pulled successfully')),
      );
      context.read<ChatService>().setModel(trimmed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pull model: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pullingModel = '';
          _pullProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Models'),
        actions: [
          const StatusIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModels,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pullController,
                    decoration: const InputDecoration(
                      hintText: 'Enter model name, e.g. llama3.2',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _pullModel,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pullingModel.isEmpty
                      ? () => _pullModel(_pullController.text)
                      : null,
                  child: const Icon(Icons.download),
                ),
              ],
            ),
          ),
          if (_pullingModel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pulling $_pullingModel...'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _pullProgress > 0 ? _pullProgress / 100.0 : null,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox.shrink(),
          Expanded(
            child: _models.isEmpty
                ? const Center(
                    child: Text('No models available. Pull a model to get started.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _models.length,
                    itemBuilder: (context, index) {
                      final model = _models[index];
                      final isPulling = _pullingModel == model.name;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(model.name),
                          subtitle: Text(
                            'Size: ${(model.size / 1024 / 1024).toStringAsFixed(1)} MB',
                          ),
                          trailing: isPulling
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _pullModel(model.name),
                                  tooltip: 'Pull model',
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
