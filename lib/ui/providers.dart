import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/providers.dart';
import '../api/models/api_models.dart' as api;

import 'models.dart';

/// 首页搜索框内容
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

/// 当前选中的省份（进入省份详情时设置）
class CurrentProvince extends Notifier<Province> {
  @override
  Province build() => kProvinces.first;

  void select(Province province) => state = province;
}

final currentProvinceProvider = NotifierProvider<CurrentProvince, Province>(
  CurrentProvince.new,
);

/// 每日推荐卡片
final dailyTopicsProvider = Provider<List<HeritageTopic>>(
  (ref) => kDailyTopics,
);

/// 热门话题卡片
final hotTopicsProvider = Provider<List<HeritageTopic>>((ref) => kHotTopics);

/// 省份非遗名录条目
final provinceEntriesProvider = Provider.family<List<HeritageEntry>, String>((
  ref,
  provinceName,
) {
  switch (provinceName) {
    case '湖北省':
      return kHubeiEntries;
    case '吉林省':
      return kJilinEntries;
    default:
      return const [];
  }
});

/// 真实名录接口。省份页面和搜索结果使用该 provider，而旧 mock 仅保留作
/// 服务不可用时的开发占位。
final remoteHeritageEntriesProvider =
    FutureProvider.family<
      List<HeritageEntry>,
      ({String? regionCode, String? level, String? query})
    >((ref, query) async {
      final data = await ref
          .watch(heritageRepositoryProvider)
          .list(
            regionCode: query.regionCode,
            query: query.query,
            levels: query.level == null
                ? null
                : [api.HeritageLevel.from(query.level!)],
          );
      return data.items.map((item) {
        final level = item.badges
            .firstWhere(
              (badge) => badge.type == 'LEVEL',
              orElse: () => const api.Badge(type: '', code: '', name: '国家级'),
            )
            .name;
        final category = item.badges
            .firstWhere(
              (badge) => badge.type == 'CATEGORY',
              orElse: () => const api.Badge(type: '', code: '', name: '传统技艺'),
            )
            .name;
        return HeritageEntry(
          id: item.id,
          title: item.nameZh,
          category: category,
          level: level,
          description: item.summary,
        );
      }).toList();
    });
