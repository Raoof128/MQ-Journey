import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class BuildingEntry {
  final String code;
  final String name;
  final String description;
  final double campusX;
  final double campusY;
  final double entranceLatitude;
  final double entranceLongitude;

  const BuildingEntry({
    required this.code,
    this.name = '',
    this.description = '',
    required this.campusX,
    required this.campusY,
    required this.entranceLatitude,
    required this.entranceLongitude,
  });
}

@immutable
class BuildingsRegistry {
  final List<BuildingEntry> buildings;

  const BuildingsRegistry({required this.buildings});

  BuildingEntry? byCode(String code) {
    final upper = code.trim().toUpperCase();
    for (final b in buildings) {
      if (b.code.toUpperCase() == upper) return b;
    }
    return null;
  }

  factory BuildingsRegistry.fromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return BuildingsRegistry(
      buildings: list
          .map((e) {
            final m = e as Map<String, dynamic>;
            return BuildingEntry(
              code: (m['code'] ?? m['id'] ?? '') as String,
              name: (m['name'] as String?) ?? '',
              description: (m['description'] as String?) ?? '',
              campusX: (m['campusX'] as num).toDouble(),
              campusY: (m['campusY'] as num).toDouble(),
              entranceLatitude:
                  (m['entranceLatitude'] ?? m['latitude'] as num?)
                      ?.toDouble() ??
                  0,
              entranceLongitude:
                  (m['entranceLongitude'] ?? m['longitude'] as num?)
                      ?.toDouble() ??
                  0,
            );
          })
          .toList(growable: false),
    );
  }
}
