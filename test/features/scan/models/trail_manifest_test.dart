import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/features/scan/domain/models/trail_manifest.dart';

void main() {
  group('TrailManifest', () {
    const validJson =
        '{"locations":[{"locationId":"lib-01","buildingId":"C3A","title":"Library"}]}';
    final manifest = TrailManifest.fromJson(validJson);

    test('contains returns true for known location', () {
      expect(manifest.contains('lib-01'), isTrue);
    });

    test('contains returns false for unknown location', () {
      expect(manifest.contains('unknown-99'), isFalse);
    });

    test('byId returns matching location', () {
      final loc = manifest.byId('lib-01');
      expect(loc, isNotNull);
      expect(loc!.title, 'Library');
      expect(loc.buildingId, 'C3A');
    });

    test('byId returns null for missing', () {
      expect(manifest.byId('unknown'), isNull);
    });

    test('fromJson handles missing buildingId', () {
      final m = TrailManifest.fromJson(
        '{"locations":[{"locationId":"gen-01","title":"Generic"}]}',
      );
      expect(m.byId('gen-01')?.buildingId, isNull);
    });

    test('rejects malformed JSON gracefully', () {
      expect(
        () => TrailManifest.fromJson('not json'),
        throwsFormatException,
      );
    });
  });
}
