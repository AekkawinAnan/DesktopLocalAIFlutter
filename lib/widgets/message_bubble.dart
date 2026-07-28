import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';

class MessageBubble extends StatelessWidget {
  final dynamic message;

  const MessageBubble({super.key, required this.message});

  List<Widget> _buildImages() {
    final images = message.images as List<dynamic>?;
    if (images == null || images.isEmpty) return [];
    return images.map((img) {
      Uint8List bytes;
      if (img is String) {
        bytes = base64Decode(img);
      } else {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue.shade700
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._buildImages(),
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}