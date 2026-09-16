import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/api_models.dart';
import '../../common/app_theme.dart';
import '../providers.dart';
import '../widgets/search_header.dart';

/// 发现页：GET /heritage-items（每日推送按最近认定，热门话题按人工排序）
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(discoverDailyProvider);
    final hot = ref.watch(discoverHotProvider);

    return Scaffold(
      appBar: SearchHeader.searchOnly(
        hintText: '搜索非遗或地区',
        leadingIcon: const Icon(
          Icons.explore_outlined,
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const _SectionTitle(title: '每日推送'),
                const SizedBox(height: 18),
                SizedBox(
                  height: 172,
                  child: daily.when(
                    loading: () => const _LoadingBlock(),
                    error: (error, stack) =>
                        const _ErrorBlock(message: '每日推送加载失败'),
                    data: (page) => PageView.builder(
                      controller: PageController(viewportFraction: 1),
                      itemCount: page.items.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _DailyCard(card: page.items[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const _SectionTitle(title: '热门话题'),
                const SizedBox(height: 18),
                hot.when(
                  loading: () => const _LoadingBlock(height: 120),
                  error: (error, stack) =>
                      const _ErrorBlock(message: '热门话题加载失败'),
                  data: (page) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 104 / 149,
                        ),
                    itemCount: page.items.length,
                    itemBuilder: (context, index) =>
                        _HotTopicCard(card: page.items[index]),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 25,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({this.height = 172});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
      ),
    );
  }
}

/// 每日推送卡片：封面图 + 名称与简介
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.card});

  final HeritageCard card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        'heritageDetail',
        pathParameters: {'heritageId': card.id},
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(url: card.coverImageUrl, name: card.nameZh),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xCC000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    card.nameZh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 热门话题卡片：封面图 + 名称
class _HotTopicCard extends StatelessWidget {
  const _HotTopicCard({required this.card});

  final HeritageCard card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        'heritageDetail',
        pathParameters: {'heritageId': card.id},
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(url: card.coverImageUrl, name: card.nameZh),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x33000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  card.nameZh,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 网络封面图，加载失败时回退到首字底色块
class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: AppColors.accent.withValues(alpha: 0.85),
      child: Center(
        child: Text(
          name.isEmpty ? '非' : name.substring(0, 1),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}
