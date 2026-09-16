import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/api_models.dart';
import '../api/providers.dart';
import '../features/map/models.dart' as map_models;
import '../features/map/providers.dart' as map_providers;

/// 顶部搜索框内容
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

/// 名录列表查询条件
typedef HeritageListQuery = ({
  String? regionCode,
  HeritageLevel? level,
  String? query,
});

/// GET /regions/{regionCode}
final regionDetailProvider = FutureProvider.family<RegionDetail, String>(
  (ref, regionCode) => ref.watch(regionRepositoryProvider).detail(regionCode),
);

/// GET /heritage-items（地区 / 级别 / 关键词）
final heritageListProvider =
    FutureProvider.family<PageData<HeritageCard>, HeritageListQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(heritageRepositoryProvider)
          .list(
            regionCode: query.regionCode,
            query: query.query,
            levels: query.level == null ? null : [query.level!],
            pageSize: 50,
          );
    });

/// 发现页「每日推送」：按最近认定年份排序
final discoverDailyProvider = FutureProvider<PageData<HeritageCard>>(
  (ref) => ref
      .watch(heritageRepositoryProvider)
      .list(sort: 'NEWEST_DESIGNATION', pageSize: 6),
);

/// 发现页「热门话题」：按人工排序取前 9 条
final discoverHotProvider = FutureProvider<PageData<HeritageCard>>(
  (ref) => ref.watch(heritageRepositoryProvider).list(pageSize: 9),
);

/// 地图页「常看省份」：中国模式下按名录数量排序的省份
final rankedProvincesProvider = FutureProvider<List<Region>>((ref) async {
  final data = await ref.watch(
    map_providers.mapRegionsDataProvider(map_models.MapMode.china).future,
  );
  final sorted = [...data]
    ..sort((a, b) => (b.totalCount ?? 0).compareTo(a.totalCount ?? 0));
  return sorted.take(4).toList();
});
