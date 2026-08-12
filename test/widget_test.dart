import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intangible_track/features/map/models.dart';
import 'package:intangible_track/features/map/interactive_map.dart';
import 'package:intangible_track/features/map/providers.dart' as map;
import 'package:intangible_track/main.dart';
import 'package:intangible_track/ui/pages/map_page.dart';
import 'package:intangible_track/ui/pages/province_detail_page.dart';
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

Widget appWithMapOverrides({Widget child = const SizedBox.shrink()}) {
  return ProviderScope(
    overrides: [
      map.mapRegionsProvider.overrideWith(
        (ref, mode) => Future.value(const <MapRegion>[]),
      ),
    ],
    child: child,
  );
}

void main() {
  testWidgets('App boots to the map tab', (WidgetTester tester) async {
    mockAssets(tester);
    await tester.pumpWidget(appWithMapOverrides(child: const MyApp()));

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
    await tester.pumpWidget(appWithMapOverrides(child: const MyApp()));

    await tester.pumpAndSettle();
    await tester.tap(find.text('发现').last);
    await tester.pumpAndSettle();

    expect(find.text('每日推送'), findsOneWidget);
    expect(find.text('热门话题'), findsOneWidget);
  });

  testWidgets('Map tab: segmented control is centered', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    await tester.pumpWidget(
      appWithMapOverrides(child: const MaterialApp(home: MapPage())),
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
      mapKey: '420000',
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
      summary: const RegionSummary(
        code: 'CN-42',
        type: RegionType.province,
        nameZh: '湖北省',
        nameEn: 'Hubei',
        description: '湖北省非物质文化遗产资源丰富。',
        mapKey: '420000',
        totalCount: 100,
        levelCounts: LevelCounts(world: 2, national: 30, provincial: 68),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          map.mapRegionsProvider.overrideWith(
            (ref, mode) => Future.value([region]),
          ),
        ],
        child: const MaterialApp(home: MapPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(InteractiveMap)));
    await tester.pumpAndSettle();

    expect(find.text('湖北省'), findsWidgets); // 弹窗标题（页面卡片也有）
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

  testWidgets('Province detail page matches design and filters by level', (
    WidgetTester tester,
  ) async {
    mockAssets(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProvinceDetailPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('湖北省非遗名录'), findsOneWidget);
    expect(find.text('搜索非遗'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('世界级'), findsNWidgets(2)); // 筛选项 + 卡片徽章
    expect(find.text('汉绣'), findsNWidgets(3));

    // 点击「国家级」筛选
    await tester.tap(find.text('国家级').first);
    await tester.pumpAndSettle();

    expect(find.text('汉绣'), findsOneWidget);
  });
}
