import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intangible_track/api/models/api_models.dart' as api;
import 'package:intangible_track/features/map/interactive_map.dart';
import 'package:intangible_track/features/map/models.dart';
import 'package:intangible_track/features/map/providers.dart' as map;
import 'package:intangible_track/main.dart';
import 'package:intangible_track/ui/pages/map_page.dart';
import 'package:intangible_track/ui/pages/province_detail_page.dart';
import 'package:intangible_track/ui/providers.dart' as ui;
import 'package:intangible_track/ui/widgets/search_header.dart';

// 测试环境不打包真实资源，这里用 1x1 透明 PNG 兜底
void mockAssets(WidgetTester tester) {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );
  const assets = [
    'assets/icons/ic_map.png',
    'assets/icons/ic_nav.png',
    'assets/icons/ic_user.png',
    'assets/山.png',
  ];
  final manifest = StandardMessageCodec().encodeMessage({
    for (final asset in assets)
      asset: [
        {'asset': asset, 'dpr': 1.0},
      ],
  });
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      if (message == null) return null;
      final key = Uri.decodeFull(
        utf8.decode(
          message.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        ),
      );
      if (key == 'AssetManifest.bin' || key == 'AssetManifest.json') {
        return manifest;
      }
      if (key.startsWith('assets/map/')) {
        return ByteData.view(utf8.encode('{}').buffer);
      }
      if (assets.contains(key)) {
        return ByteData.view(png.buffer);
      }
      return null;
    },
  );
}

const _hubei = api.Region(
  code: '420000',
  type: 'PROVINCE',
  nameZh: '湖北省',
  nameEn: 'Hubei',
  description: '湖北省非物质文化遗产资源丰富。',
  totalCount: 2,
  levelCounts: api.LevelCounts(world: 1, national: 2, provincial: 1),
);

api.HeritageCard _card({
  required String id,
  required String name,
  required String levelCode,
  required String levelName,
}) {
  return api.HeritageCard(
    id: id,
    code: 'CODE-$id',
    nameZh: name,
    nameEn: null,
    location: const api.Location(
      countryCode: 'CHN',
      provinceCode: '420000',
      cityCode: '420100',
      displayText: '湖北省武汉市',
    ),
    summary: '$name简介',
    coverImageUrl: '',
    badges: [
      api.Badge(type: 'LEVEL', code: levelCode, name: levelName),
      const api.Badge(type: 'CATEGORY', code: 'TRADITIONAL_ART', name: '传统美术'),
    ],
    isFavorited: false,
  );
}

final _hanxiu = _card(
  id: '019c9f00-0000-7000-8000-001000011000',
  name: '汉绣',
  levelCode: 'NATIONAL',
  levelName: '国家级',
);

final _hanju = _card(
  id: '019c9f00-0000-7000-8000-001000012000',
  name: '汉剧',
  levelCode: 'PROVINCIAL',
  levelName: '省级',
);

api.PageData<api.HeritageCard> _page(List<api.HeritageCard> items) =>
    api.PageData(
      items: items,
      page: 1,
      pageSize: 50,
      total: items.length,
      totalPages: 1,
    );

Widget appWithOverrides({Widget child = const SizedBox.shrink()}) {
  return ProviderScope(
    overrides: [
      map.mapRegionsProvider.overrideWith(
        (ref, mode) => Future.value(const <MapRegion>[]),
      ),
      map.mapRegionsDataProvider.overrideWith(
        (ref, mode) => Future.value(const <api.Region>[_hubei]),
      ),
      ui.discoverDailyProvider.overrideWith(
        (ref) => Future.value(_page([_hanxiu])),
      ),
      ui.discoverHotProvider.overrideWith(
        (ref) => Future.value(_page([_hanxiu, _hanju])),
      ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('App boots to the map tab', (WidgetTester tester) async {
    mockAssets(tester);
    await tester.pumpWidget(appWithOverrides(child: const MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('中国地图'), findsOneWidget);
    expect(find.text('常看省份'), findsOneWidget);
    expect(find.text('地图'), findsWidgets);
    expect(find.text('发现'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });

  testWidgets('Bottom nav switches to discover tab', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    await tester.pumpWidget(appWithOverrides(child: const MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('发现').last);
    await tester.pumpAndSettle();

    expect(find.text('每日推送'), findsOneWidget);
    expect(find.text('热门话题'), findsOneWidget);
    expect(find.text('汉绣'), findsWidgets);
  });

  testWidgets('Map tab: segmented control is centered', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    await tester.pumpWidget(
      appWithOverrides(child: const MaterialApp(home: MapPage())),
    );
    await tester.pumpAndSettle();

    final screenCenter = tester.getSize(find.byType(MapPage)).width / 2;
    final chinaCenter = tester.getCenter(find.text('中国地图'));
    final worldCenter = tester.getCenter(find.text('世界地图'));
    final pairCenter = (chinaCenter.dx + worldCenter.dx) / 2;

    expect(pairCenter, moreOrLessEquals(screenCenter, epsilon: 1));
  });

  testWidgets('Map page shows region bottom sheet on tap', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    final region = MapRegion(
      regionCode: '420000',
      nameZh: '湖北省',
      nameEn: 'Hubei',
      geometry: RegionGeometry([
        [
          const [
            GeoPoint(0, 0),
            GeoPoint(10, 0),
            GeoPoint(10, 10),
            GeoPoint(0, 10),
            GeoPoint(0, 0),
          ],
        ],
      ]),
      summary: _hubei,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          map.mapRegionsProvider.overrideWith(
            (ref, mode) => Future.value([region]),
          ),
          map.mapRegionsDataProvider.overrideWith(
            (ref, mode) => Future.value(const <api.Region>[_hubei]),
          ),
        ],
        child: const MaterialApp(home: MapPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(InteractiveMap)));
    await tester.pumpAndSettle();

    expect(find.text('取消'), findsOneWidget);
    expect(find.text('世界级名录'), findsOneWidget);
    expect(find.text('国家级名录'), findsOneWidget);
    expect(find.text('省级重点保护'), findsOneWidget);
    expect(find.text('进入该省名录库'), findsOneWidget);
    expect(find.text('湖北省非物质文化遗产资源丰富。'), findsOneWidget);
  });

  testWidgets('Search header: search icon inside field and icons aligned', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: SearchHeader.searchOnly(
              hintText: '搜索非遗或地区',
              leadingIcon: Icon(Icons.location_on_outlined),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchIcon = find.byIcon(Icons.search);
    final leadingIcon = find.byIcon(Icons.location_on_outlined);
    expect(searchIcon, findsOneWidget);
    expect(leadingIcon, findsOneWidget);

    final searchCenter = tester.getCenter(searchIcon);
    final leadingCenter = tester.getCenter(leadingIcon);

    // 两个图标垂直居中在同一水平线上
    expect(searchCenter.dy, moreOrLessEquals(leadingCenter.dy, epsilon: 0.5));
    // 放大镜位于输入框内，在左侧图标右侧
    expect(searchCenter.dx, greaterThan(leadingCenter.dx));
  });

  testWidgets('Province detail page loads region and filters by level', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ui.regionDetailProvider.overrideWith(
            (ref, code) => Future.value(
              const api.RegionDetail(
                region: _hubei,
                parent: null,
                breadcrumb: [],
              ),
            ),
          ),
          ui.heritageListProvider.overrideWith(
            (ref, query) => Future.value(
              query.level == null ? _page([_hanxiu, _hanju]) : _page([_hanxiu]),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProvinceDetailPage(regionCode: '420000'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('湖北省非遗名录'), findsOneWidget);
    expect(find.text('搜索非遗'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('汉绣'), findsOneWidget);
    expect(find.text('汉剧'), findsOneWidget);

    // 切换「国家级」筛选后只保留国家级条目
    await tester.tap(find.text('国家级').first);
    await tester.pumpAndSettle();

    expect(find.text('汉绣'), findsOneWidget);
    expect(find.text('汉剧'), findsNothing);
  });

  testWidgets('Heritage card opens detail route with the item id', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    final router = GoRouter(
      initialLocation: '/province',
      routes: [
        GoRoute(
          path: '/province',
          builder: (context, state) =>
              const ProvinceDetailPage(regionCode: '420000'),
        ),
        GoRoute(
          path: '/heritage/:heritageId',
          name: 'heritageDetail',
          builder: (context, state) => Scaffold(
            body: Text('DETAIL:${state.pathParameters['heritageId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ui.regionDetailProvider.overrideWith(
            (ref, code) => Future.value(
              const api.RegionDetail(
                region: _hubei,
                parent: null,
                breadcrumb: [],
              ),
            ),
          ),
          ui.heritageListProvider.overrideWith(
            (ref, query) => Future.value(_page([_hanxiu, _hanju])),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('汉绣'));
    await tester.pumpAndSettle();

    expect(find.text('DETAIL:${_hanxiu.id}'), findsOneWidget);
  });
}
