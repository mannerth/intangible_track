import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// 单个地区的几何与名称
class RegionGeometryEntry {
  const RegionGeometryEntry({
    required this.name,
    required this.nameZh,
    required this.geometry,
    this.labelAnchor,
  });

  final String name;
  final String nameZh;
  final RegionGeometry geometry;

  /// 推荐的标注锚点（世界地图来自 Natural Earth LABEL_X/Y，中国为 polylabel 结果）
  final GeoPoint? labelAnchor;
}

/// 从内置 GeoJSON 资产加载几何数据
class MapGeometryLoader {
  static const _chinaAsset = 'assets/map/china.json';
  static const _worldAsset = 'assets/map/world.json';

  static Future<Map<String, RegionGeometryEntry>> load(MapMode mode) async {
    final asset = mode == MapMode.china ? _chinaAsset : _worldAsset;
    final raw = await rootBundle.loadString(asset);
    return parse(raw);
  }

  /// 解析 GeoJSON 资产内容（可测试）
  static Map<String, RegionGeometryEntry> parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in data.entries)
        entry.key: _entryFromJson(entry.value as Map<String, dynamic>),
    };
  }

  static RegionGeometryEntry _entryFromJson(Map<String, dynamic> json) {
    final polygons = <GeoPolygon>[];
    for (final rawPoly in json['polygons'] as List<dynamic>) {
      final poly = <List<GeoPoint>>[];
      for (final rawRing in rawPoly as List<dynamic>) {
        poly.add([
          for (final p in rawRing as List<dynamic>)
            GeoPoint(
              ((p as List)[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ),
        ]);
      }
      polygons.add(poly);
    }
    final labelX = json['labelX'];
    final labelY = json['labelY'];
    return RegionGeometryEntry(
      name: json['name'] as String? ?? '',
      nameZh: json['nameZh'] as String? ?? (json['name'] as String? ?? ''),
      geometry: RegionGeometry(polygons),
      labelAnchor: labelX is num && labelY is num
          ? GeoPoint(labelX.toDouble(), labelY.toDouble())
          : null,
    );
  }
}
