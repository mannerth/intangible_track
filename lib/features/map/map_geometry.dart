import 'dart:ui';

import 'models.dart';

/// 射线法判断点是否在环内（map 坐标：x=lon, y=-lat）
bool pointInRing(Offset point, List<GeoPoint> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = ring[i].lon, yi = -ring[i].lat;
    final xj = ring[j].lon, yj = -ring[j].lat;
    if (((yi > point.dy) != (yj > point.dy)) &&
        (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// 点是否在多边形内（所有环做奇偶测试，处理内环空洞）
bool pointInPolygon(Offset point, GeoPolygon polygon) {
  var crossings = 0;
  for (final ring in polygon) {
    if (pointInRing(point, ring)) crossings++;
  }
  return crossings.isOdd;
}

/// 点是否在地区几何内
bool pointInGeometry(Offset point, RegionGeometry geometry) =>
    geometry.polygons.any((poly) => pointInPolygon(point, poly));

/// 命中检测：先精确命中，未命中时在容差范围内取离质心最近的地区。
MapRegion? hitTestRegion(
  Iterable<MapRegion> regions,
  Offset geoPoint, {
  double toleranceMap = 0.01,
}) {
  MapRegion? nearest;
  var nearestDistance = double.infinity;
  for (final region in regions) {
    final b = region.geometry.bounds;
    final minX = b.minX - toleranceMap, minY = b.minY - toleranceMap;
    final maxX = b.maxX + toleranceMap, maxY = b.maxY + toleranceMap;
    if (geoPoint.dx < minX || geoPoint.dx > maxX) continue;
    if (geoPoint.dy < minY || geoPoint.dy > maxY) continue;
    if (pointInGeometry(geoPoint, region.geometry)) return region;
    final distance =
        (geoPoint - Offset((b.minX + b.maxX) / 2, (b.minY + b.maxY) / 2))
            .distance;
    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearest = region;
    }
  }
  return nearest;
}
