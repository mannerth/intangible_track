import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:intangible_track/features/map/map_geometry_loader.dart';

void main() {
  test('parse real china geometry json', () {
    final raw = File('assets/map/china.json').readAsStringSync();
    final entry = MapGeometryLoader.parse(raw);
    expect(entry.length, greaterThan(30));
    expect(entry['420000']?.nameZh, '湖北省');
    expect(entry['420000']?.geometry.polygons, isNotEmpty);
    expect(entry['420000']?.labelAnchor, isNotNull);
  });

  test('parse real world geometry json', () {
    final raw = File('assets/map/world.json').readAsStringSync();
    final entry = MapGeometryLoader.parse(raw);
    expect(entry.length, greaterThan(150));
    expect(entry['CHN']?.nameZh, '中华人民共和国');
    expect(entry['CHN']?.labelAnchor, isNotNull);
  });
}
