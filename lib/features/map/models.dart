/// 地图模式，与后端 MapMode 枚举一致
enum MapMode {
  china('CHINA'),
  world('WORLD');

  const MapMode(this.apiValue);

  final String apiValue;

  static MapMode fromApi(String value) =>
      MapMode.values.firstWhere((m) => m.apiValue == value);
}

/// 地区类型
enum RegionType {
  country('COUNTRY'),
  province('PROVINCE'),
  city('CITY'),
  district('DISTRICT');

  const RegionType(this.apiValue);

  final String apiValue;
}

/// 非遗等级计数
class LevelCounts {
  const LevelCounts({
    required this.world,
    required this.national,
    required this.provincial,
  });

  final int world;
  final int national;
  final int provincial;

  int get total => world + national + provincial;
}

/// 地区概要（后端 RegionSummary）
class RegionSummary {
  const RegionSummary({
    required this.code,
    required this.type,
    required this.nameZh,
    required this.nameEn,
    required this.description,
    required this.mapKey,
    required this.totalCount,
    required this.levelCounts,
  });

  final String code;
  final RegionType type;
  final String nameZh;
  final String? nameEn;
  final String description;
  final String? mapKey;
  final int totalCount;
  final LevelCounts levelCounts;
}

/// 地图地区列表（后端 RegionListData）
class RegionListData {
  const RegionListData({
    required this.mapMode,
    required this.regions,
    required this.requestId,
  });

  final MapMode mapMode;
  final List<RegionSummary> regions;
  final String requestId;
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

/// 前端地图使用的完整地区（几何 + 概要元数据）
class MapRegion {
  const MapRegion({
    required this.mapKey,
    required this.nameZh,
    required this.geometry,
    this.nameEn,
    this.labelAnchor,
    this.summary,
  });

  final String mapKey;
  final String nameZh;
  final String? nameEn;
  final RegionGeometry geometry;

  /// 标注锚点（经纬度）；为空时回退到质心
  final GeoPoint? labelAnchor;
  final RegionSummary? summary;
}
