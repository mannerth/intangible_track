import 'package:flutter_riverpod/flutter_riverpod.dart';

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
