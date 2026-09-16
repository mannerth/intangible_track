import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/api_models.dart';
import '../../api/providers.dart';
import '../../common/app_theme.dart';

/// “我的”页下的海报列表，对应 GET /me/posters。
class PostersPage extends ConsumerWidget {
  const PostersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posters = ref.watch(postersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const _PostersHeader(),
      body: posters.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) =>
            _PostersError(onRetry: () => ref.invalidate(postersProvider)),
        data: (page) => page.items.isEmpty
            ? const _EmptyPosters()
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () async => ref.invalidate(postersProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(41, 42, 41, 32),
                  itemCount: page.items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 30,
                    childAspectRatio: 145 / 208,
                  ),
                  itemBuilder: (context, index) =>
                      _PosterCard(poster: page.items[index]),
                ),
              ),
      ),
    );
  }
}

class _PostersHeader extends StatelessWidget implements PreferredSizeWidget {
  const _PostersHeader();

  @override
  Size get preferredSize => const Size.fromHeight(157);

  @override
  Widget build(BuildContext context) => Container(
    height: preferredSize.height,
    decoration: const BoxDecoration(
      color: AppColors.header,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: .3,
          child: Image.asset('assets/山.png', fit: BoxFit.cover),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          '海报',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 51),
                padding: const EdgeInsets.only(left: 16, right: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '搜索非遗',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    Icon(Icons.search, size: 20, color: AppColors.textHint),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.poster});
  final Poster poster;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.pushNamed(
      'heritagePoster',
      pathParameters: {'heritageId': poster.heritageItem.id},
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Image.network(
        poster.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) =>
            Image.asset('assets/hanxiu/poster.png', fit: BoxFit.cover),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const ColoredBox(
                color: Color(0xFFF5F0E4),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
      ),
    ),
  );
}

class _EmptyPosters extends StatelessWidget {
  const _EmptyPosters();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome_outlined, size: 58, color: AppColors.textLight),
        SizedBox(height: 15),
        Text(
          '还没有生成海报',
          style: TextStyle(fontSize: 16, color: AppColors.textHint),
        ),
        SizedBox(height: 7),
        Text(
          '在非遗详情页生成你的第一张海报',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    ),
  );
}

class _PostersError extends StatelessWidget {
  const _PostersError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('海报加载失败', style: TextStyle(color: AppColors.textHint)),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}
