import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ollama_process.dart';
import 'screens/engine_setup_screen.dart';
import 'screens/chat_screen.dart';
import '../services/chat_service.dart';
import 'screens/model_selector.dart';
import 'screens/settings_screen.dart';
import 'screens/receipt_scanner_screen.dart';

class OllamaSidecarApp extends StatelessWidget {
  const OllamaSidecarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatService(),
      child: MaterialApp(
        title: 'Ollama Sidecar',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const InitializationScreen(),
          '/chat': (context) => const ChatScreen(),
          '/engine-setup': (context) => const EngineSetupScreen(),
          '/models': (context) => const ModelSelector(),
          '/settings': (context) => const SettingsScreen(),
          '/receipt-scanner': (context) => const ReceiptScannerScreen(),
        },
      ),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final running = await OllamaSystemService.isOllamaRunning();
    if (!mounted) return;
    if (running) {
      Navigator.of(context).pushReplacementNamed('/chat');
    } else {
      Navigator.of(context).pushReplacementNamed('/engine-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
