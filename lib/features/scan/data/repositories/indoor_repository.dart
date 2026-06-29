import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:mq_journey/features/scan/domain/models/indoor_manifest.dart';

class IndoorRepository {
  Future<IndoorManifest?> load(String buildingId) async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/indoor/${buildingId.toLowerCase()}.json',
      );
      return IndoorManifest.fromJson(raw);
    } on FlutterError {
      return null;
    }
  }
}
