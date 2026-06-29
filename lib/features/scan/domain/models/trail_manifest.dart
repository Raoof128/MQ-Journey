import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class TrailLocation {
  final String locationId;
  final String? buildingId;
  final String title;

  const TrailLocation({
    required this.locationId,
    this.buildingId,
    required this.title,
  });
}

@immutable
class TrailManifest {
  final List<TrailLocation> locations;

  const TrailManifest({required this.locations});

  bool contains(String locationId) =>
      locations.any((l) => l.locationId == locationId);

  TrailLocation? byId(String locationId) {
    for (final l in locations) {
      if (l.locationId == locationId) return l;
    }
    return null;
  }

  factory TrailManifest.fromJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final locs = (json['locations'] as List)
        .map((e) {
          final m = e as Map<String, dynamic>;
          return TrailLocation(
            locationId: m['locationId'] as String,
            buildingId: m['buildingId'] as String?,
            title: m['title'] as String,
          );
        })
        .toList(growable: false);
    return TrailManifest(locations: locs);
  }
}
