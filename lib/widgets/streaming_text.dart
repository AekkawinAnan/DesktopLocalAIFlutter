import 'package:flutter/material.dart';

class StreamingText extends StatelessWidget {
  final String text;

  const StreamingText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'monospace'),
    );
  }
}