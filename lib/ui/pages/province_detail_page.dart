import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/api_models.dart' as api;
import '../../api/providers.dart';
import '../../common/app_theme.dart';
import '../providers.dart';
import '../widgets/search_header.dart';

/// 省份 / 国家名录页：GET /regions/{regionCode} + GET /heritage-items?regionCode=
class ProvinceDetailPage extends ConsumerStatefulWidget {
  const ProvinceDetailPage({super.key, required this.regionCode});

  final String regionCode;

  @override
  ConsumerState<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends ConsumerState<ProvinceDetailPage> {
  static const _filters = <({String label, api.HeritageLevel? level})>[
    (label: '全部', level: null),
    (label: '世界级', level: api.HeritageLevel.world),
    (label: '国家级', level: api.HeritageLevel.national),
    (label: '省级重点', level: api.HeritageLevel.provincial),
  ];

  int _selectedFilter = 0;

  HeritageListQuery get _query => (
    regionCode: widget.regionCode,
    level: _filters[_selectedFilter].level,
    query: null,
  );

  Future<void> _toggleFavorite(api.HeritageCard card) async {
    final session = ref.read(sessionProvider).value;
    if (session == null || !session.signedIn) {
      await context.pushNamed('login');
      return;
    }
    final repository = ref.read(userRepositoryProvider);
    try {
      if (card.isFavorited ?? false) {
        await repository.unfavorite(card.id);
      } else {
        await repository.favorite(card.id);
      }
      ref.invalidate(heritageListProvider(_query));
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(regionDetailProvider(widget.regionCode));
    final list = ref.watch(heritageListProvider(_query));
    final name = region.value?.region.nameZh;

    return Scaffold(
      appBar: SearchHeader.titled(
        title: name == null ? '非遗名录' : '$name非遗名录',
        hintText: '搜索非遗',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        children: [
          _FilterBar(
            selectedIndex: _selectedFilter,
            onChanged: (index) => setState(() => _selectedFilter = index),
          ),
          const SizedBox(height: 28),
          list.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
            error: (error, stack) => _ErrorState(
              message: '名录加载失败',
              onRetry: () => ref.invalidate(heritageListProvider(_query)),
            ),
            data: (page) => page.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        '暂无名录数据',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < page.items.length; i++) ...[
                        _HeritageCard(
                          card: page.items[i],
                          onTap: () => context.pushNamed(
                            'heritageDetail',
                            pathParameters: {'heritageId': page.items[i].id},
                          ),
                          onFavoriteToggle: () =>
                              _toggleFavorite(page.items[i]),
                        ),
                        if (i < page.items.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
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
          for (var i = 0; i < _ProvinceDetailPageState._filters.length; i++)
            Expanded(
              child: _FilterChip(
                label: _ProvinceDetailPageState._filters[i].label,
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
    required this.card,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final api.HeritageCard card;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  api.Badge? get _levelBadge =>
      card.badges.where((badge) => badge.type == 'LEVEL').firstOrNull;

  api.Badge? get _categoryBadge =>
      card.badges.where((badge) => badge.type == 'CATEGORY').firstOrNull;

  Color get _levelColor => switch (_levelBadge?.code) {
    'WORLD' => const Color(0x99D40000),
    'NATIONAL' => const Color(0x96D27650),
    _ => const Color(0x99F39C12),
  };

  @override
  Widget build(BuildContext context) {
    final levelBadge = _levelBadge;
    final categoryBadge = _categoryBadge;
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                _Cover(url: card.coverImageUrl, name: card.nameZh),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.nameZh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (levelBadge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              height: 16,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _levelColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                levelBadge.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          _FavoriteButton(
                            isFavorite: card.isFavorited ?? false,
                            onTap: onFavoriteToggle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (categoryBadge != null)
                        Text(
                          categoryBadge.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        card.summary,
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

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
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
        name.isEmpty ? '非' : name.substring(0, 1),
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite ? AppColors.accent : AppColors.textLight,
        ),
      ),
    );
  }
}
