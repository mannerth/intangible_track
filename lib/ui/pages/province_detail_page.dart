import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/app_theme.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets/search_header.dart';

class ProvinceDetailPage extends ConsumerStatefulWidget {
  const ProvinceDetailPage({super.key});

  @override
  ConsumerState<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends ConsumerState<ProvinceDetailPage> {
  static const _levels = ['全部', '世界级', '国家级', '省级重点'];

  int _selectedLevel = 0;
  final Set<String> _favoriteTitles = <String>{};

  @override
  Widget build(BuildContext context) {
    final province = ref.watch(currentProvinceProvider);
    final remoteEntries = ref.watch(
      remoteHeritageEntriesProvider((
        regionCode: null,
        level: null,
        query: null,
      )),
    );
    final List<HeritageEntry> entries =
        remoteEntries.asData?.value ??
        ref.watch(provinceEntriesProvider(province.name));
    final visible = _selectedLevel == 0
        ? entries
        : entries.where((e) => e.level == _levels[_selectedLevel]).toList();

    return Scaffold(
      appBar: SearchHeader.titled(
        title: '${province.name}非遗名录',
        hintText: '搜索非遗',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        children: [
          _FilterBar(
            selectedIndex: _selectedLevel,
            onChanged: (index) => setState(() => _selectedLevel = index),
          ),
          const SizedBox(height: 28),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  '暂无名录数据',
                  style: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
              ),
            )
          else
            for (var i = 0; i < visible.length; i++) ...[
              _HeritageCard(
                entry: visible[i],
                isFavorite: _favoriteTitles.contains(visible[i].title),
                onFavoriteToggle: () => setState(() {
                  final title = visible[i].title;
                  _favoriteTitles.contains(title)
                      ? _favoriteTitles.remove(title)
                      : _favoriteTitles.add(title);
                }),
              ),
              if (i < visible.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x33E5E5E5),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _ProvinceDetailPageState._levels.length; i++)
            Expanded(
              child: _FilterChip(
                label: _ProvinceDetailPageState._levels[i],
                selected: selectedIndex == i,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        // 两种状态均占用相同的点击与布局空间，切换筛选时列表不会横向跳动。
        width: double.infinity,
        height: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: selected ? 16 : 14,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected ? AppColors.accent : AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeritageCard extends StatelessWidget {
  const _HeritageCard({
    required this.entry,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final HeritageEntry entry;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  Color get _levelColor => switch (entry.level) {
    '国家级' => const Color(0x96D27650),
    '世界级' => const Color(0x99D40000),
    _ => const Color(0x99F39C12),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      // 预留 8px 的垂直呼吸空间：缩略图保持 100px，文字与收藏按钮不会
      // 因字体度量/设备像素取整而溢出卡片底部。
      height: 128,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x24D9D9D9),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pushNamed('heritageDetail', extra: entry.title),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                // 缩略图
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD27650), Color(0xFFE8A87C)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.title.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 17),
                // 内容区
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            decoration: BoxDecoration(
                              color: _levelColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.level,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: isFavorite ? '取消收藏' : '收藏',
                            onPressed: onFavoriteToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: isFavorite
                                  ? AppColors.accent
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          color: AppColors.textHint.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
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
