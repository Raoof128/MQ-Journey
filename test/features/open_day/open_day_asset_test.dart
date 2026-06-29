import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/features/open_day/domain/entities/open_day_data.dart';

/// Integrity guard for the official Open Day dataset
/// (`assets/data/open_day.json`, sourced from the MQ Open Day 2026 PDF).
///
/// Catches data drift: every session/stop must point at a real building code,
/// every event must reference known degrees, and the schedule must parse.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OpenDayData data;
  late Set<String> buildingKeys;

  setUpAll(() async {
    final odRaw = await rootBundle.loadString('assets/data/open_day.json');
    data = OpenDayData.fromJson(jsonDecode(odRaw) as Map<String, dynamic>);

    final bRaw = await rootBundle.loadString('assets/data/buildings.json');
    final buildings = (jsonDecode(bRaw) as List).cast<Map<String, dynamic>>();
    buildingKeys = {
      for (final b in buildings) (b['code'] as String).toUpperCase(),
      for (final b in buildings) (b['id'] as String).toUpperCase(),
    };
  });

  test('dataset parses with the expected shape', () {
    expect(data.studyAreas, isNotEmpty);
    expect(data.bachelors, isNotEmpty);
    expect(data.events, isNotEmpty);
    expect(data.suggestedStops, isNotEmpty);
  });

  test('every bachelor maps to a known study area', () {
    final areaIds = {for (final a in data.studyAreas) a.id};
    for (final b in data.bachelors) {
      expect(
        areaIds.contains(b.studyAreaId),
        isTrue,
        reason: '${b.id} -> unknown study area ${b.studyAreaId}',
      );
    }
  });

  test('every event building code resolves in the registry', () {
    for (final e in data.events) {
      final code = e.buildingCode;
      if (code == null || code.isEmpty) continue;
      expect(
        buildingKeys.contains(code.toUpperCase()),
        isTrue,
        reason: 'event ${e.id} -> unmappable building "$code"',
      );
    }
  });

  test('every suggested stop building code resolves in the registry', () {
    for (final s in data.suggestedStops) {
      final code = s.buildingCode;
      if (code == null || code.isEmpty) continue;
      expect(
        buildingKeys.contains(code.toUpperCase()),
        isTrue,
        reason: 'stop ${s.id} -> unmappable building "$code"',
      );
    }
  });

  test('every referenced bachelorId exists in the bachelor list', () {
    final ids = {for (final b in data.bachelors) b.id};
    for (final e in data.events) {
      for (final id in e.bachelorIds) {
        expect(ids.contains(id), isTrue, reason: 'event ${e.id} -> $id');
      }
    }
    for (final s in data.suggestedStops) {
      for (final id in s.bachelorIds) {
        expect(ids.contains(id), isTrue, reason: 'stop ${s.id} -> $id');
      }
    }
  });

  test('every session is the official 45-minute length', () {
    for (final e in data.events) {
      expect(
        e.endTime.difference(e.startTime),
        const Duration(minutes: 45),
        reason: '${e.id} is not 45 minutes',
      );
    }
  });
}
