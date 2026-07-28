import 'package:flutter/material.dart';
import '../models/ollama_model.dart';
import '../services/ollama_api.dart';
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

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await OllamaApi().checkConnection();
      if (!isConnected) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load models: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pullModel(String modelName) async {
    setState(() {
      _pullingModel = modelName;
      _pullProgress = 0;
    });

    try {
      await OllamaApi().pullModel(
        modelName,
        onProgress: (completed) {
          setState(() {
            _pullProgress = completed;
          });
        },
      );
      _loadModels();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model "$modelName" pulled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pull model: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _pullingModel = '';
        _pullProgress = 0;
      });
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
          if (_isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox.shrink(),
          Expanded(
            child: _models.isEmpty
                ? const Center(child: Text('No models available. Pull a model to get started.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _models.length,
                    itemBuilder: (context, index) {
                      final model = _models[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(model.name),
                          subtitle: Text(
                            'Size: ${(model.size / 1024 / 1024).toStringAsFixed(1)} MB',
                          ),
                          trailing: _pullingModel == model.name
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: _pullProgress > 0
                                        ? _pullProgress / 100.0
                                        : null,
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