import 'models.dart';

/// 地区列表数据源。
///
/// 当前为 Mock 实现，遵循后端接口契约（RegionListData）；
/// 后续接入网络时只需替换 [fetchRegions] 的实现。
class MapRegionRepository {
  const MapRegionRepository();

  Future<RegionListData> fetchRegions(MapMode mode, {String? q}) async {
    final regions = switch (mode) {
      MapMode.china => _chinaRegions(),
      MapMode.world => _worldRegions(),
    };
    final query = q?.trim() ?? '';
    final filtered = query.isEmpty
        ? regions
        : regions
              .where(
                (r) =>
                    r.nameZh.contains(query) ||
                    (r.nameEn?.toLowerCase().contains(query.toLowerCase()) ??
                        false),
              )
              .toList();
    return RegionListData(
      mapMode: mode,
      regions: filtered,
      requestId: 'req_mock_${mode.apiValue.toLowerCase()}',
    );
  }

  List<RegionSummary> _chinaRegions() => [
    for (final (code, nameZh, nameEn) in _china)
      _summary(code, nameZh, nameEn, RegionType.province),
  ];

  List<RegionSummary> _worldRegions() => [
    for (final (code, nameZh, nameEn) in _world)
      _summary(code, nameZh, nameEn, RegionType.country),
  ];

  RegionSummary _summary(
    String code,
    String nameZh,
    String nameEn,
    RegionType type,
  ) {
    final total = 45 + (code.hashCode.abs() % 700);
    final world = 2 + (code.hashCode.abs() % 3);
    final national = 20 + (code.hashCode.abs() % 120);
    return RegionSummary(
      code: code,
      type: type,
      nameZh: nameZh,
      nameEn: nameEn,
      description: '$nameZh非物质文化遗产资源丰富，汇聚了当地世代相传的传统技艺与民俗智慧。',
      mapKey: code,
      totalCount: total,
      levelCounts: LevelCounts(
        world: world,
        national: national,
        provincial: (total - world - national).clamp(0, total),
      ),
    );
  }
}

/// (mapKey / code, nameZh, nameEn)
const _china = [
  ('110000', '北京市', 'Beijing'),
  ('120000', '天津市', 'Tianjin'),
  ('130000', '河北省', 'Hebei'),
  ('140000', '山西省', 'Shanxi'),
  ('150000', '内蒙古自治区', 'Inner Mongolia'),
  ('210000', '辽宁省', 'Liaoning'),
  ('220000', '吉林省', 'Jilin'),
  ('230000', '黑龙江省', 'Heilongjiang'),
  ('310000', '上海市', 'Shanghai'),
  ('320000', '江苏省', 'Jiangsu'),
  ('330000', '浙江省', 'Zhejiang'),
  ('340000', '安徽省', 'Anhui'),
  ('350000', '福建省', 'Fujian'),
  ('360000', '江西省', 'Jiangxi'),
  ('370000', '山东省', 'Shandong'),
  ('410000', '河南省', 'Henan'),
  ('420000', '湖北省', 'Hubei'),
  ('430000', '湖南省', 'Hunan'),
  ('440000', '广东省', 'Guangdong'),
  ('450000', '广西壮族自治区', 'Guangxi'),
  ('460000', '海南省', 'Hainan'),
  ('500000', '重庆市', 'Chongqing'),
  ('510000', '四川省', 'Sichuan'),
  ('520000', '贵州省', 'Guizhou'),
  ('530000', '云南省', 'Yunnan'),
  ('540000', '西藏自治区', 'Tibet'),
  ('610000', '陕西省', 'Shaanxi'),
  ('620000', '甘肃省', 'Gansu'),
  ('630000', '青海省', 'Qinghai'),
  ('640000', '宁夏回族自治区', 'Ningxia'),
  ('650000', '新疆维吾尔自治区', 'Xinjiang'),
  ('710000', '台湾省', 'Taiwan'),
  ('810000', '香港特别行政区', 'Hong Kong'),
  ('820000', '澳门特别行政区', 'Macao'),
];

const _world = [
  ('CHN', '中华人民共和国', 'China'),
  ('USA', '美国', 'United States'),
  ('JPN', '日本', 'Japan'),
  ('KOR', '韩国', 'South Korea'),
  ('PRK', '朝鲜', 'North Korea'),
  ('MNG', '蒙古', 'Mongolia'),
  ('RUS', '俄罗斯', 'Russia'),
  ('IND', '印度', 'India'),
  ('PAK', '巴基斯坦', 'Pakistan'),
  ('NPL', '尼泊尔', 'Nepal'),
  ('BTN', '不丹', 'Bhutan'),
  ('BGD', '孟加拉国', 'Bangladesh'),
  ('LKA', '斯里兰卡', 'Sri Lanka'),
  ('MMR', '缅甸', 'Myanmar'),
  ('THA', '泰国', 'Thailand'),
  ('LAO', '老挝', 'Laos'),
  ('VNM', '越南', 'Vietnam'),
  ('KHM', '柬埔寨', 'Cambodia'),
  ('MYS', '马来西亚', 'Malaysia'),
  ('SGP', '新加坡', 'Singapore'),
  ('IDN', '印度尼西亚', 'Indonesia'),
  ('PHL', '菲律宾', 'Philippines'),
  ('FRA', '法国', 'France'),
  ('DEU', '德国', 'Germany'),
  ('GBR', '英国', 'United Kingdom'),
  ('ITA', '意大利', 'Italy'),
  ('ESP', '西班牙', 'Spain'),
  ('PRT', '葡萄牙', 'Portugal'),
  ('NLD', '荷兰', 'Netherlands'),
  ('BEL', '比利时', 'Belgium'),
  ('CHE', '瑞士', 'Switzerland'),
  ('AUT', '奥地利', 'Austria'),
  ('POL', '波兰', 'Poland'),
  ('CZE', '捷克', 'Czechia'),
  ('HUN', '匈牙利', 'Hungary'),
  ('ROU', '罗马尼亚', 'Romania'),
  ('GRC', '希腊', 'Greece'),
  ('TUR', '土耳其', 'Turkey'),
  ('EGY', '埃及', 'Egypt'),
  ('MAR', '摩洛哥', 'Morocco'),
  ('ZAF', '南非', 'South Africa'),
  ('NGA', '尼日利亚', 'Nigeria'),
  ('KEN', '肯尼亚', 'Kenya'),
  ('ETH', '埃塞俄比亚', 'Ethiopia'),
  ('BRA', '巴西', 'Brazil'),
  ('ARG', '阿根廷', 'Argentina'),
  ('MEX', '墨西哥', 'Mexico'),
  ('CAN', '加拿大', 'Canada'),
  ('AUS', '澳大利亚', 'Australia'),
  ('NZL', '新西兰', 'New Zealand'),
];
