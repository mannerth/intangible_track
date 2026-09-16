import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/api_models.dart' as api;
import '../../ui/providers.dart';
import '../../api/providers.dart';
import 'map_geometry_loader.dart';
import 'map_region_repository.dart';
import 'models.dart';

/// 当前地图模式（中国 / 世界）
class MapModeController extends Notifier<MapMode> {
  @override
  MapMode build() => MapMode.china;

  void set(MapMode mode) => state = mode;
}

final mapModeProvider = NotifierProvider<MapModeController, MapMode>(
  MapModeController.new,
);

final mapRegionRepositoryProvider = Provider<MapRegionRepository>(
  (ref) => MapRegionRepository(ref.watch(regionRepositoryProvider)),
);

/// 几何数据（内置 GeoJSON）
final mapGeometryProvider =
    FutureProvider.family<Map<String, RegionGeometryEntry>, MapMode>(
      (ref, mode) => MapGeometryLoader.load(mode),
    );

/// 地区列表：GET /regions?mapMode=&q=（q 为空时返回全量）
final mapRegionsDataProvider = FutureProvider.family<List<api.Region>, MapMode>(
  (ref, mode) {
    final q = ref.watch(searchQueryProvider);
    return ref.watch(mapRegionRepositoryProvider).fetchRegions(mode, q: q);
  },
);

/// 合并几何与地区概要，供地图组件使用
final mapRegionsProvider = FutureProvider.family<List<MapRegion>, MapMode>((
  ref,
  mode,
) async {
  final geometry = await ref.watch(mapGeometryProvider(mode).future);
  final data = await ref.watch(mapRegionsDataProvider(mode).future);
  // 地区编码（中国=行政区划码、世界=ISO 三位码）即前端几何键。
  final byKey = {for (final r in data) r.code: r};
  return [
    for (final entry in geometry.entries)
      MapRegion(
        regionCode: entry.key,
        nameZh: byKey[entry.key]?.nameZh ?? entry.value.nameZh,
        nameEn: byKey[entry.key]?.nameEn ?? entry.value.name,
        geometry: entry.value.geometry,
        labelAnchor: entry.value.labelAnchor,
        summary: byKey[entry.key],
      ),
  ];
});

/// 当前选中地区
class SelectedRegion extends Notifier<MapRegion?> {
  @override
  MapRegion? build() => null;

  void select(MapRegion? region) => state = region;
}

final selectedRegionProvider = NotifierProvider<SelectedRegion, MapRegion?>(
  SelectedRegion.new,
);
