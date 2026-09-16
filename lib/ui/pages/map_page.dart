import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/api_models.dart';
import '../../common/app_theme.dart';
import '../../features/map/interactive_map.dart';
import '../../features/map/models.dart';
import '../../features/map/providers.dart' as map;
import '../providers.dart';
import '../widgets/search_header.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  void _onRegionTap(MapRegion region) {
    ref.read(map.selectedRegionProvider.notifier).select(region);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      isScrollControlled: true,
      builder: (_) => _RegionSheet(
        region: region,
        onOpenList: () {
          Navigator.of(context).pop();
          context.pushNamed(
            'provinceDetail',
            pathParameters: {'regionCode': region.regionCode},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapMode = ref.watch(map.mapModeProvider);
    final regionsAsync = ref.watch(map.mapRegionsProvider(mapMode));
    final selected = ref.watch(map.selectedRegionProvider);
    final provinces = ref.watch(rankedProvincesProvider);

    return Scaffold(
      appBar: SearchHeader.searchOnly(
        hintText: '搜索非遗或地区',
        leadingIcon: const Icon(
          Icons.location_on_outlined,
          size: 22,
          color: AppColors.textSecondary,
        ),
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).update(value),
      ),
      // 地图区固定，下方列表独立滚动，避免地图手势与页面滚动冲突
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _MapSwitch(
                    mode: mapMode,
                    onChanged: (mode) {
                      ref
                          .read(map.selectedRegionProvider.notifier)
                          .select(null);
                      ref.read(map.mapModeProvider.notifier).set(mode);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mapMode == MapMode.china ? '查看中国各省的非遗名录库' : '查看世界各地的非遗名录库',
                  style: const TextStyle(fontSize: 12, color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MapArea(
                mode: mapMode,
                regionsAsync: regionsAsync,
                selectedKey: selected?.regionCode,
                onRegionTap: _onRegionTap,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
              children: [
                const Row(
                  children: [
                    Text(
                      '常看省份',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '新增',
                      style: TextStyle(fontSize: 14, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '快捷前往近期热门或历史常看的省份',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                provinces.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => const Text(
                    '省份列表加载失败',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  data: (items) => Column(
                    children: [
                      for (
                        var row = 0;
                        row < (items.length / 2).ceil();
                        row++
                      ) ...[
                        Row(
                          children: [
                            for (var i = 0; i < 2; i++) ...[
                              if (row * 2 + i < items.length)
                                Expanded(
                                  child: _ProvinceCard(
                                    province: items[row * 2 + i],
                                    highlighted: row == 0,
                                    onTap: () {
                                      final region = items[row * 2 + i];
                                      context.pushNamed(
                                        'provinceDetail',
                                        pathParameters: {
                                          'regionCode': region.code,
                                        },
                                      );
                                    },
                                  ),
                                )
                              else
                                const Spacer(),
                              if (i == 0) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapArea extends StatelessWidget {
  const _MapArea({
    required this.mode,
    required this.regionsAsync,
    required this.selectedKey,
    required this.onRegionTap,
  });

  final MapMode mode;
  final AsyncValue<List<MapRegion>> regionsAsync;
  final String? selectedKey;
  final ValueChanged<MapRegion> onRegionTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: regionsAsync.when(
        data: (regions) => InteractiveMap(
          mode: mode,
          regions: regions,
          selectedKey: selectedKey,
          onRegionTap: onRegionTap,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        error: (error, stack) => const Center(
          child: Text('地图加载失败', style: TextStyle(color: AppColors.textHint)),
        ),
      ),
    );
  }
}

/// 点击地区后的底部弹窗（地图页能力），按视觉稿样式实现
class _RegionSheet extends StatelessWidget {
  const _RegionSheet({required this.region, required this.onOpenList});

  final MapRegion region;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final summary = region.summary;
    final description = summary?.description ?? '该地区暂未收录非遗数据，敬请期待。';
    final hasData = summary != null;
    final counts = summary?.levelCounts;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(35, 14, 35, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 右上角取消
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(fontSize: 16, color: AppColors.textHint),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // 居中标题 + 右侧小图标
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      region.nameZh,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.place_outlined,
                      size: 24,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Color(0x80000000),
                  ),
                ),
                if (counts != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _StatCard(
                        count: counts.world,
                        label: '世界级名录',
                        countColor: const Color(0xFFA52A3C),
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        count: counts.national,
                        label: '国家级名录',
                        countColor: Colors.black,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        count: counts.provincial,
                        label: '省级重点保护',
                        countColor: Colors.black,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.7),
                      disabledBackgroundColor: const Color(0xFFE0D6C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: hasData ? onOpenList : null,
                    child: Text(
                      hasData ? '进入该省名录库' : '暂无数据',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.count,
    required this.label,
    required this.countColor,
  });

  final int count;
  final String label;
  final Color countColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0x3BD9D9D9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: countColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSwitch extends StatelessWidget {
  const _MapSwitch({required this.mode, required this.onChanged});

  final MapMode mode;
  final ValueChanged<MapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Segment(
          label: '中国地图',
          active: mode == MapMode.china,
          onTap: () => onChanged(MapMode.china),
        ),
        const SizedBox(width: 28),
        _Segment(
          label: '世界地图',
          active: mode == MapMode.world,
          onTap: () => onChanged(MapMode.world),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              color: active ? AppColors.accent : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceCard extends StatelessWidget {
  const _ProvinceCard({
    required this.province,
    required this.highlighted,
    required this.onTap,
  });

  final Region province;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.header : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  province.nameZh.isEmpty
                      ? '非'
                      : province.nameZh.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      province.nameZh,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${province.totalCount ?? 0} 项名录',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
