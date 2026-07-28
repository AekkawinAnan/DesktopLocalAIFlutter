import 'package:flutter/material.dart';
import '../services/ollama_process.dart';

class EngineSetupScreen extends StatefulWidget {
  const EngineSetupScreen({super.key});

  @override
  State<EngineSetupScreen> createState() => _EngineSetupScreenState();
}

class _EngineSetupScreenState extends State<EngineSetupScreen> {
  bool _isChecking = true;
  bool _engineFound = false;
  bool _isInstalling = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkEngineStatus();
  }

  Future<void> _checkEngineStatus() async {
    setState(() => _isChecking = true);
    final running = await OllamaSystemService.isOllamaRunning();
    if (!mounted) return;
    setState(() {
      _engineFound = running;
      _isChecking = false;
    });
    if (running) {
      Navigator.of(context).pushReplacementNamed('/chat');
    }
  }

  Future<void> _installEngine() async {
    setState(() {
      _isInstalling = true;
      _statusMessage = 'กำลังดาวน์โหลด Ollama Installer...';
    });

    try {
      await OllamaSystemService.installOllama();
      setState(() {
        _statusMessage = 'ติดตั้ง Ollama เรียบร้อยแล้ว! กำลังเริ่มต้น...';
      });

      await Future.delayed(const Duration(seconds: 2));
      await OllamaSystemService.startOllama();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ollama พร้อมใช้งานแล้ว!')),
      );
      Navigator.of(context).pushReplacementNamed('/chat');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'ติดตั้งไม่สำเร็จ: $e';
        _isInstalling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ติดตั้งไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.memory_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isChecking
                    ? 'กำลังตรวจสอบ AI Engine...'
                    : _engineFound
                        ? 'AI Engine พร้อมใช้งาน'
                        : 'ไม่พบ AI Engine ในเครื่อง',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _engineFound
                    ? 'กำลังเชื่อมต่อกับ Ollama ที่ localhost:11434'
                    : 'แอปต้องการ Ollama สำหรับทำงาน การติดตั้งจะช่วยดาวน์โหลดและตั้งค่าให้อัตโนมัติ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (_isInstalling) ...[
                Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_statusMessage),
                  ],
                ),
              ] else if (!_engineFound && !_isChecking)
                ElevatedButton.icon(
                  onPressed: _installEngine,
                  icon: const Icon(Icons.download),
                  label: const Text('ติดตั้ง Ollama อัตโนมัติ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              else if (_engineFound)
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/chat'),
                  child: const Text('เริ่มต้นใช้งาน'),
                ),
              const SizedBox(height: 16),
              if (_isChecking)
                const CircularProgressIndicator()
              else if (!_engineFound && !_isInstalling)
                TextButton.icon(
                  onPressed: _checkEngineStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ตรวจสอบอีกครั้ง'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
