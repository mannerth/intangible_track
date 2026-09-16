import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intangible_track/features/map/interactive_map.dart';
import 'package:intangible_track/features/map/map_geometry.dart';
import 'package:intangible_track/features/map/map_painter.dart';
import 'package:intangible_track/features/map/map_viewport_controller.dart';
import 'package:intangible_track/features/map/models.dart';

MapRegion _squareRegion(String key, String name) {
  return MapRegion(
    regionCode: key,
    nameZh: name,
    geometry: RegionGeometry([
      [
        const [
          GeoPoint(0, 0),
          GeoPoint(10, 0),
          GeoPoint(10, 10),
          GeoPoint(0, 10),
          GeoPoint(0, 0),
        ],
      ],
    ]),
  );
}

void main() {
  group('map geometry', () {
    test('point in polygon', () {
      final ring = const [
        GeoPoint(0, 0),
        GeoPoint(10, 0),
        GeoPoint(10, 10),
        GeoPoint(0, 10),
        GeoPoint(0, 0),
      ];
      expect(pointInRing(const Offset(5, -5), ring), isTrue);
      expect(pointInRing(const Offset(15, -5), ring), isFalse);
    });

    test('hit test inside / outside / tolerance', () {
      final regions = [_squareRegion('A', '甲')];
      expect(hitTestRegion(regions, const Offset(5, -5))?.regionCode, 'A');
      expect(hitTestRegion(regions, const Offset(50, -50)), isNull);
      // 紧邻边界时通过容差命中
      expect(
        hitTestRegion(
          regions,
          const Offset(10.001, -5),
          toleranceMap: 0.01,
        )?.regionCode,
        'A',
      );
    });
  });

  group('label anchor', () {
    test('prefers data anchor over centroid', () {
      final region = MapRegion(
        regionCode: 'A',
        nameZh: '甲',
        geometry: RegionGeometry([
          [
            const [
              GeoPoint(0, 0),
              GeoPoint(10, 0),
              GeoPoint(10, 10),
              GeoPoint(0, 10),
              GeoPoint(0, 0),
            ],
          ],
        ]),
        labelAnchor: const GeoPoint(3, 3),
      );
      final info = RegionPaintInfo.build([region]).single;
      expect(info.anchor, const Offset(3, -3));
    });

    test('falls back to centroid when no anchor', () {
      final region = _squareRegion('A', '甲');
      final info = RegionPaintInfo.build([region]).single;
      // 正方形质心即中心
      expect(info.anchor, const Offset(5, -5));
    });
  });

  group('adaptive label font', () {
    test('sizes adapt to region width', () {
      // 两个全角字，宽 30px：fit=13.8 → 封顶 12
      expect(MapPainter.adaptiveFontSizeFor('中国', 30), 12);
      // 宽 16px：fit=7.36 → 7.36
      expect(
        MapPainter.adaptiveFontSizeFor('中国', 16),
        moreOrLessEquals(7.36, epsilon: 1e-9),
      );
      // 宽 10px：最小字号也放不下 → 不显示
      expect(MapPainter.adaptiveFontSizeFor('中国', 10), isNull);
      // 半角字符按 0.62em 估算
      expect(
        MapPainter.adaptiveFontSizeFor('USA', 20),
        moreOrLessEquals(20 * 0.92 / (0.62 * 3), epsilon: 1e-9),
      );
      // 选中地区允许大一号
      expect(MapPainter.adaptiveFontSizeFor('中国', 100, selected: true), 13);
    });
  });

  group('map viewport controller', () {
    test('fit target honors ratio and offsets', () {
      final controller = MapViewportController(fitRatio: 0.7);
      controller.updateSize(const Size(400, 300));
      final target = controller.fitTargetFor(
        const GeoBounds(minX: 0, minY: -10, maxX: 10, maxY: 0),
      );
      // min(400/10, 300/10) * 0.7 = 21
      expect(target.scale, moreOrLessEquals(21, epsilon: 1e-9));
      expect(target.center.dx, moreOrLessEquals(5, epsilon: 1e-9));
      expect(target.center.dy, moreOrLessEquals(-5, epsilon: 1e-9));
    });

    test('zoom is clamped within limits', () {
      final controller = MapViewportController(
        fitRatio: 0.7,
        scaleMin: 0.5,
        scaleMax: 100,
      );
      controller.updateSize(const Size(400, 300));
      controller.configure(
        allBounds: const GeoBounds(minX: 0, minY: -10, maxX: 10, maxY: 0),
        focusBounds: null,
        mode: MapMode.china,
      );
      controller.zoomIn();
      expect(controller.scale, lessThanOrEqualTo(100));
      controller.zoomOut();
      controller.zoomOut();
      controller.zoomOut();
      controller.zoomOut();
      expect(controller.scale, greaterThanOrEqualTo(0.5));
    });
  });

  group('interactive map widget', () {
    testWidgets('tap on a region reports it', (tester) async {
      MapRegion? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: InteractiveMap(
                mode: MapMode.china,
                regions: [_squareRegion('A', '甲')],
                onRegionTap: (r) => tapped = r,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 150));
      await tester.pumpAndSettle();

      expect(tapped?.regionCode, 'A');
    });

    testWidgets('tap outside region does not report', (tester) async {
      MapRegion? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: InteractiveMap(
                mode: MapMode.china,
                regions: [_squareRegion('A', '甲')],
                onRegionTap: (r) => tapped = r,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(30, 30));
      await tester.pumpAndSettle();

      expect(tapped, isNull);
    });

    testWidgets('custom paint has non-empty size and paints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: InteractiveMap(
                mode: MapMode.china,
                regions: [_squareRegion('A', '甲')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paintRender = tester.renderObject<RenderCustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(paintRender.size.isEmpty, isFalse);
    });
  });
}
