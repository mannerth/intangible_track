import '../../api/models/api_models.dart' as api;
import '../../api/repositories.dart';
import 'models.dart';

/// 地区列表数据源。
///
/// 当前为 Mock 实现，遵循后端接口契约（RegionListData）；
/// 后续接入网络时只需替换 [fetchRegions] 的实现。
class MapRegionRepository {
  const MapRegionRepository(this._repository);
  final RegionRepository _repository;

  Future<RegionListData> fetchRegions(MapMode mode, {String? q}) async {
    final data = await _repository.list(
      mode == MapMode.china ? api.ApiMapMode.china : api.ApiMapMode.world,
      query: q,
    );
    final regions = data.regions.map(_fromApi).toList();
    return RegionListData(
      mapMode: data.mapMode == api.ApiMapMode.china
          ? MapMode.china
          : MapMode.world,
      regions: regions,
      requestId: '',
    );
  }

  RegionSummary _fromApi(api.Region json) {
    final counts = json.levelCounts;
    return RegionSummary(
      code: json.code,
      type: RegionType.values.firstWhere(
        (v) => v.apiValue == json.type,
        orElse: () => RegionType.province,
      ),
      nameZh: json.nameZh,
      nameEn: json.nameEn,
      description: json.description ?? '',
      mapKey: json.mapKey,
      totalCount: json.totalCount ?? 0,
      levelCounts: LevelCounts(
        world: counts?.world ?? 0,
        national: counts?.national ?? 0,
        provincial: counts?.provincial ?? 0,
      ),
    );
  }
}
