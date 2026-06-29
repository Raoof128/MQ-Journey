import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/features/scan/data/repositories/indoor_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IndoorRepository', () {
    test('returns null for missing building', () async {
      final repo = IndoorRepository();
      final manifest = await repo.load('nonexistent');
      expect(manifest, isNull);
    });
  });
}
