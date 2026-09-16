import '../../api/models/api_models.dart' as api;

/// 地图模式，与后端 MapMode 枚举一致
enum MapMode {
  china('CHINA'),
  world('WORLD');

  const MapMode(this.apiValue);

  final String apiValue;

  static MapMode fromApi(String value) =>
      MapMode.values.firstWhere((m) => m.apiValue == value);
}

/// 地理坐标（经纬度）
class GeoPoint {
  const GeoPoint(this.lon, this.lat);

  final double lon;
  final double lat;
}

/// 一个多边形（多个环，首环为外环，其余为内环）
typedef GeoPolygon = List<List<GeoPoint>>;

/// 地区的几何边界（GeoJSON Polygon / MultiPolygon）
class RegionGeometry {
  const RegionGeometry(this.polygons);

  final List<GeoPolygon> polygons;

  /// 包围盒（map 坐标：x=lon, y=-lat）
  ({double minX, double minY, double maxX, double maxY}) get bounds {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final poly in polygons) {
      for (final ring in poly) {
        for (final p in ring) {
          final x = p.lon, y = -p.lat;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }
}

/// 前端地图使用的完整地区（本地几何 + 接口地区数据）
class MapRegion {
  const MapRegion({
    required this.regionCode,
    required this.nameZh,
    required this.geometry,
    this.nameEn,
    this.labelAnchor,
    this.summary,
  });

  /// 地区编码，同时作为前端几何数据的键（中国=行政区划码，世界=ISO 三位码）
  final String regionCode;
  final String nameZh;
  final String? nameEn;
  final RegionGeometry geometry;

  /// 标注锚点（经纬度）；为空时回退到质心
  final GeoPoint? labelAnchor;

  /// 接口返回的地区数据；几何存在但接口未收录时为 null
  final api.Region? summary;
}
