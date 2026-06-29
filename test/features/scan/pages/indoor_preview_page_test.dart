import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/features/scan/presentation/pages/indoor_preview_page.dart';
import 'package:mq_journey/features/scan/providers/scan_providers.dart';
import 'package:mq_journey/features/scan/domain/models/indoor_manifest.dart';

void main() {
  testWidgets('shows loading indicator when provider is loading', (tester) async {
    final completer = Completer<IndoorManifest?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          indoorManifestProvider.overrideWith((ref, id) => completer.future),
        ],
        child: const MaterialApp(
          home: IndoorPreviewPage(buildingId: 'C3A'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(null);
  });

  testWidgets('shows no preview when manifest is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          indoorManifestProvider.overrideWith((ref, id) async => null),
        ],
        child: const MaterialApp(
          home: IndoorPreviewPage(buildingId: 'C3A'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No indoor preview available'), findsOneWidget);
  });

  testWidgets('shows no preview when manifest is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          indoorManifestProvider.overrideWith(
            (ref, id) async => const IndoorManifest(nodes: []),
          ),
        ],
        child: const MaterialApp(
          home: IndoorPreviewPage(buildingId: 'C3A'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No indoor preview available'), findsOneWidget);
  });
}
