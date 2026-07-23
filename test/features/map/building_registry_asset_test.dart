import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/features/map/domain/entities/building.dart';
import 'package:mq_journey/features/map/domain/entities/campus_overlay_meta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled building registry mirrors the audited web dataset', () async {
    final raw = await rootBundle.loadString('assets/data/buildings.json');
    final data = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Building.fromJson)
        .toList();

    expect(data.length, greaterThanOrEqualTo(100));

    final byId = <String, Building>{
      for (final building in data) building.id: building,
    };

    for (final buildingId in const [
      'LIB',
      '18WW',
      '1CC',
      'MUSE',
      '14SCO',
      '12WW',
    ]) {
      final building = byId[buildingId];
      expect(building, isNotNull);
      expect(building!.entranceLatitude, isNotNull);
      expect(building.entranceLongitude, isNotNull);
      expect(building.campusX, isNotNull);
      expect(building.campusY, isNotNull);
    }
  });

  test(
    'bundled campus overlay metadata matches the shared web export',
    () async {
      final raw = await rootBundle.loadString(
        'assets/data/campus_overlay_meta.json',
      );
      final meta = CampusOverlayMeta.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );

      expect(meta.imageAsset, 'assets/maps/mq-campus.png');
      expect(meta.width, greaterThan(4000));
      expect(meta.height, greaterThan(3000));
      expect(meta.pixelBounds.north, meta.height);
      expect(meta.pixelBounds.east, meta.width);
      // Building pins and GPS-derived points now live in the SAME pixel
      // space: `campusX/campusY` are generated from `gpsProjection.affine`,
      // which is itself calibrated against the campus map's own printed grid.
      // The old non-zero X offset existed only to nudge hand-placed pins
      // toward a differently-calibrated transform; carrying it now would
      // shift every pin 80px (~29m) away from the user-location dot.
      expect(meta.buildingPixelOffsetX, 0);
      expect(meta.mapNorth, lessThanOrEqualTo(85));
      expect(meta.mapEast, lessThanOrEqualTo(170));
      expect(meta.gpsProjection?.method, 'gcp_affine');
      expect(meta.gpsProjection?.affine, isNotNull);
    },
  );

  // ── Georeferencing regression guard ────────────────────────────
  //
  // `assets/maps/mq-campus.png` carries a printed reference grid: 31 numbered
  // columns of 141.5px starting at x=84.75, and 22 lettered rows (A..W, no I)
  // of 142.5px starting at y=61.75 — measured off the raster itself, and each
  // cell is one 50m square of the map's scale bar. Every building's `gridRef`
  // is the cell the university's own cartography puts it in, so it is the one
  // piece of ground truth that is independent of both our GPS data and our
  // pixel pins.
  //
  // This locks the calibration: if someone re-fits `gpsProjection.affine`,
  // regenerates `campusX/campusY`, or swaps the map raster without redoing the
  // other two, the pins drift off the drawn buildings and this fails.
  //
  // Tolerances are aggregate, not per-building: a `gridRef` only resolves a
  // position to within one 201px cell diagonal, so a perfectly calibrated set
  // still scatters ~82px (median) around the cell centres purely from that
  // quantisation. Individual outliers are known bad *source data* (see the
  // 2026-07-23 changelog entry), not calibration error.
  test('building pins agree with the campus map printed grid', () async {
    const columnWidth = 141.5, columnOrigin = 84.75;
    const rowHeight = 142.5, rowOrigin = 61.75;
    const rowLetters = 'ABCDEFGHJKLMNOPQRSTUVW';

    final raw = await rootBundle.loadString('assets/data/buildings.json');
    final buildings = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Building.fromJson)
        .toList();

    final distances = <double>[];
    var exactCell = 0;

    for (final building in buildings) {
      final ref = building.gridRef;
      final point = building.campusPoint;
      if (ref == null || point == null || ref.length < 2) continue;
      final row = rowLetters.indexOf(ref[0].toUpperCase());
      final column = int.tryParse(ref.substring(1));
      if (row < 0 || column == null) continue;

      final centreX = columnOrigin + (column - 0.5) * columnWidth;
      final centreY = rowOrigin + (row + 0.5) * rowHeight;
      final dx = point.x - centreX, dy = point.y - centreY;
      distances.add(math.sqrt(dx * dx + dy * dy));

      final landedColumn = ((point.x - columnOrigin) / columnWidth).floor() + 1;
      final landedRow = ((point.y - rowOrigin) / rowHeight).floor();
      if (landedColumn == column && landedRow == row) exactCell++;
    }

    expect(
      distances.length,
      greaterThanOrEqualTo(60),
      reason: 'gridRef coverage regressed — the guard lost its ground truth',
    );

    distances.sort();
    final median = distances[distances.length ~/ 2];
    expect(
      median,
      lessThan(100),
      reason:
          'median pin is ${median.toStringAsFixed(0)}px from its grid cell '
          'centre; the calibrated set sits at ~77px. The affine, the pins and '
          'the map raster have drifted out of sync.',
    );
    expect(
      exactCell / distances.length,
      greaterThan(0.45),
      reason:
          'only $exactCell/${distances.length} pins land in their own grid '
          'cell; the calibrated set lands 36/67.',
    );
  });
}
