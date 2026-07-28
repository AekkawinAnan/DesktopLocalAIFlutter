import 'package:flutter/material.dart';
import 'package:ollama_sidecar_app/services/ollama_process.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _ollamaBinaryPath = '';
  String _modelsDirectory = '';
  String _ollamaVersion = '';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final binaryPath = await OllamaSystemService.getOllamaBinaryPath();
      final modelsDir = await OllamaSystemService.getModelsDirectory();
      final version = await OllamaSystemService.getOllamaVersion();
      final running = await OllamaSystemService.isOllamaRunning();

      setState(() {
        _ollamaBinaryPath = binaryPath;
        _modelsDirectory = modelsDir;
        _ollamaVersion = version;
        _isRunning = running;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleOllama() async {
    try {
      if (_isRunning) {
        await OllamaSystemService.stopOllama();
      } else {
        await OllamaSystemService.startOllama();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle Ollama: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: 'Server Status'),
          ListTile(
            leading: Icon(
              _isRunning ? Icons.check_circle : Icons.error,
              color: _isRunning ? Colors.green : Colors.red,
            ),
            title: Text(_isRunning ? 'Running' : 'Stopped'),
            subtitle: Text('Version: $_ollamaVersion'),
          ),
          const Divider(),
          SectionHeader(title: 'Paths'),
          ListTile(
            title: const Text('Ollama Binary'),
            subtitle: Text(_ollamaBinaryPath),
          ),
          ListTile(
            title: const Text('Models Directory'),
            subtitle: Text(_modelsDirectory),
          ),
          const Divider(),
          SectionHeader(title: 'Actions'),
          ListTile(
            leading: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            title: Text(_isRunning ? 'Stop Ollama' : 'Start Ollama'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _toggleOllama,
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Status'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _loadSettings,
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}