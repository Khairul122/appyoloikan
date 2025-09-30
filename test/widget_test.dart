import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appyoloikan/main.dart';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FishDetectorApp());
    
    expect(find.byType(FishDetectorApp), findsOneWidget);
  });
}
