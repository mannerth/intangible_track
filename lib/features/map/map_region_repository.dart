import '../../api/models/api_models.dart' as api;
import '../../api/repositories.dart';
import 'models.dart';

/// 地图地区数据源：GET /regions?mapMode=&q=
class MapRegionRepository {
  const MapRegionRepository(this._repository);

  final RegionRepository _repository;

  Future<List<api.Region>> fetchRegions(MapMode mode, {String? q}) async {
    final data = await _repository.list(
      mode == MapMode.china ? api.ApiMapMode.china : api.ApiMapMode.world,
      query: q,
    );
    return data.regions;
  }
}
