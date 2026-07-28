import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ollama_sidecar_app/app.dart';

void main() {
  testWidgets('OllamaSidecarApp loads and shows chat screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OllamaSidecarApp());

    expect(find.text('Ollama Sidecar'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}