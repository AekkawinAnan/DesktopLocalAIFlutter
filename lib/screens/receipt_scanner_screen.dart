import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ollama_sidecar_app/services/ollama_api.dart';
import 'package:ollama_sidecar_app/services/ollama_process.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final List<Map<String, String>> _extractedItems = [];
  bool _isScanning = false;
  String? _rawResponse;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนบิล/ใบเสร็จ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('เลือกรูปภาพบิล/ใบเสร็จ'),
            ),
            const SizedBox(height: 12),
            if (_images.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _images[index],
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty && !_isScanning)
              ElevatedButton.icon(
                onPressed: _scanReceipt,
                icon: const Icon(Icons.document_scanner),
                label: const Text('สแกนและแปลงเป็น CSV'),
              ),
            const SizedBox(height: 16),
            if (_isScanning)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('กำลังอ่านภาพด้วย AI...'),
                ],
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'ผิดพลาด: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_extractedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'ผลลัพธ์',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('รายการ')),
                    DataColumn(label: Text('จำนวน')),
                    DataColumn(label: Text('ราคา')),
                  ],
                  rows: _extractedItems.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['item'] ?? '')),
                        DataCell(Text(item['quantity'] ?? '')),
                        DataCell(Text(item['price'] ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download),
                label: const Text('ส่งออก CSV'),
              ),
              const SizedBox(height: 16),
            ],
            if (_rawResponse != null) ...[
              const SizedBox(height: 16),
              const Text('Raw output', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_rawResponse!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _error = null;
        });
        _images.add(File(image.path));
      }
    } catch (e) {
      setState(() {
        _error = 'เลือกรูปภาพไม่สำเร็จ: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')),
        );
      }
    }
  }

  Future<void> _scanReceipt() async {
    if (_images.isEmpty) return;

    final running = await OllamaSystemService.isOllamaRunning();
    if (!running) {
      setState(() {
        _error = 'Ollama ไม่ได้รันอยู่ กรุณาเริ่มบริการก่อน';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ollama ไม่ได้รันอยู่ กรุณาเริ่มบริการก่อน'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final api = OllamaApi();
    setState(() {
      _isScanning = true;
      _error = null;
      _extractedItems.clear();
      _rawResponse = null;
    });

    try {
      final bytes = await _images.first.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userMessage = <String, dynamic>{
        'role': 'user',
        'content': 'นี่คือรูปภาพบิลหรือใบเสร็จ โปรดอ่านรายการสินค้า/บริการ จำนวน และราคาจากภาพ แล้วส่งกลับในรูปแบบ CSV: item,quantity,price',
        'images': [base64Image],
      };

      debugPrint('ReceiptScanner: selected image bytes=${bytes.length} base64=${base64Image.length}');
      debugPrint('ReceiptScanner: sending chat request to gemma3:4b with images=${(userMessage['images'] as List).length}');

      String fullText = '';
      bool receivedAny = false;
      String? streamError;

      try {
        final stream = api.chatStream(
          model: 'gemma3:4b',
          messages: [userMessage],
        );

        await for (final chunk in stream) {
          receivedAny = true;
          debugPrint('ReceiptScanner: chunk keys=${chunk.keys.toList()}');
          if (chunk['done'] == true) {
            if (fullText.isEmpty) {
              final message = chunk['message'] as Map<String, dynamic>?;
              if (message != null) {
                final content = message['content'];
                if (content is String) {
                  fullText = content;
                } else if (content != null) {
                  fullText = content.toString();
                }
              }
            }
            break;
          }

          final message = chunk['message'] as Map<String, dynamic>?;
          if (message != null) {
            final content = message['content'];
            if (content is String) {
              fullText += content;
            } else if (content != null) {
              fullText += content.toString();
            }
          }
        }
      } on Exception catch (e) {
        streamError = 'Streaming failed: $e';
        debugPrint('ReceiptScanner: $streamError');
      }

      if (!receivedAny || streamError != null) {
        final reason = streamError ?? 'AI ไม่ตอบกลับ';
        setState(() {
          _error = '$reason — ตรวจสอบว่า gemma3:4b install แล้วและรันอยู่';
          _rawResponse = streamError ?? '(no response chunks)';
        });
        return;
      }

      debugPrint('ReceiptScanner: fullText=${fullText.isEmpty ? "(empty)" : fullText}');

      _parseCsv(fullText);

      setState(() {
        _rawResponse = fullText.isEmpty ? '(empty response)' : fullText;
      });
    } catch (e) {
      setState(() {
        _error = 'สแกนไม่สำเร็จ: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _parseCsv(String response) {
    final lines = const LineSplitter().convert(response.trim());
    final items = <Map<String, String>>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.toLowerCase().startsWith('item,quantity,price')) continue;
      final parts = line.split(',');
      if (parts.length >= 3) {
        items.add({
          'item': parts[0].trim(),
          'quantity': parts[1].trim(),
          'price': parts[2].trim(),
        });
      }
    }

    setState(() {
      _extractedItems.clear();
      _extractedItems.addAll(items);
    });
  }

  Future<void> _exportCsv() async {
    if (_extractedItems.isEmpty) return;
      final buffer = StringBuffer();
      buffer.writeln('item,quantity,price');
    for (final item in _extractedItems) {
      buffer.writeln('${item['item']},${item['quantity']},${item['price']}');
    }

    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final downloadsDir = Directory('$homeDir/Downloads/OllamaSidecar');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File('${downloadsDir.path}/receipt_$timestamp.csv');
      final bytes = Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF]);
      final sink = file.openWrite();
      sink.add(bytes);
      sink.add(utf8.encode(buffer.toString()));
      await sink.flush();
      await sink.close();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึก CSV ที่ ${file.path}'),
          action: SnackBarAction(
            label: 'เปิดโฟลเดอร์',
            onPressed: () async {
              try {
                final result = await Process.run('open', [downloadsDir.path]);
                if (result.exitCode != 0 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เปิดโฟลเดอร์ไม่สำเร็จ')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เปิดโฟลเดอร์ไม่สำเร็จ')),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึก CSV ไม่สำเร็จ: $e')),
        );
      }
    }
  }
}
