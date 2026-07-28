import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/chat_service.dart';
import 'screens/chat_screen.dart';
import 'screens/model_selector.dart';
import 'screens/settings_screen.dart';

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
          '/': (context) => const ChatScreen(),
          '/models': (context) => const ModelSelector(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}