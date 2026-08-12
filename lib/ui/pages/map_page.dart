import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/app_theme.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets/search_header.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  bool _chinaMap = true;

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _MapSwitch(
                    chinaMap: _chinaMap,
                    onChanged: (v) => setState(() => _chinaMap = v),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _chinaMap ? '查看中国各省的非遗名录库' : '查看世界各地的非遗名录库',
                  style: const TextStyle(fontSize: 12, color: AppColors.accent),
                ),
                const SizedBox(height: 20),
                _MapPlaceholder(chinaMap: _chinaMap),
                const SizedBox(height: 34),
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
                for (var row = 0; row < 2; row++) ...[
                  Row(
                    children: [
                      for (var i = 0; i < kProvinces.length; i++) ...[
                        Expanded(
                          child: _ProvinceCard(
                            province: kProvinces[i],
                            highlighted: row == 0,
                            onTap: () {
                              ref
                                  .read(currentProvinceProvider.notifier)
                                  .select(kProvinces[i]);
                              context.pushNamed('provinceDetail');
                            },
                          ),
                        ),
                        if (i == 0) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSwitch extends StatelessWidget {
  const _MapSwitch({required this.chinaMap, required this.onChanged});

  final bool chinaMap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Segment(label: '中国地图', active: chinaMap, onTap: () => onChanged(true)),
        const SizedBox(width: 28),
        _Segment(
          label: '世界地图',
          active: !chinaMap,
          onTap: () => onChanged(false),
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

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.chinaMap});

  final bool chinaMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 258,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E7CF),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              chinaMap ? 'assets/icons/ic_map.png' : 'assets/山.png',
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.85),
            ),
          ),
          if (!chinaMap)
            const Center(
              child: Text(
                '世界地图 · 敬请期待',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
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

  final Province province;
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
                  province.name.substring(0, 1),
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
                      province.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      province.items.join(' · '),
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
