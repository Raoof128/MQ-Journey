import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/features/scan/presentation/pages/scan_page.dart';

void main() {
  testWidgets('renders scan page with app bar and torch toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ScanPage())),
    );
    await tester.pump();
    expect(find.byType(ScanPage), findsOneWidget);
    expect(find.byIcon(Icons.flash_off), findsOneWidget);
  });
}
