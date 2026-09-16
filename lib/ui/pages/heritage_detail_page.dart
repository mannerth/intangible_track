import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/api_models.dart';
import '../../api/providers.dart';
import '../../common/app_theme.dart';

/// 非遗详情页：GET /heritage-items/{heritageId}
class HeritageDetailPage extends ConsumerStatefulWidget {
  const HeritageDetailPage({super.key, required this.heritageId});

  final String heritageId;

  @override
  ConsumerState<HeritageDetailPage> createState() => _HeritageDetailPageState();
}

class _HeritageDetailPageState extends ConsumerState<HeritageDetailPage> {
  bool _gallery = false;

  Future<void> _toggleFavorite(HeritageDetail detail) async {
    final session = ref.read(sessionProvider).value;
    if (session == null || !session.signedIn) {
      await context.pushNamed('login');
      return;
    }
    final repository = ref.read(userRepositoryProvider);
    try {
      if (detail.card.isFavorited ?? false) {
        await repository.unfavorite(widget.heritageId);
      } else {
        await repository.favorite(widget.heritageId);
      }
      ref.invalidate(heritageDetailProvider(widget.heritageId));
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(heritageDetailProvider(widget.heritageId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, stack) => _DetailError(
          onRetry: () =>
              ref.invalidate(heritageDetailProvider(widget.heritageId)),
        ),
        data: (value) => _DetailBody(
          detail: value,
          gallery: _gallery,
          onGalleryChanged: (gallery) => setState(() => _gallery = gallery),
          onFavoriteToggle: () => _toggleFavorite(value),
          onPosterTap: () => context.pushNamed(
            'heritagePoster',
            pathParameters: {'heritageId': widget.heritageId},
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.gallery,
    required this.onGalleryChanged,
    required this.onFavoriteToggle,
    required this.onPosterTap,
  });

  final HeritageDetail detail;
  final bool gallery;
  final ValueChanged<bool> onGalleryChanged;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPosterTap;

  String get _levelLabel {
    final level = detail.card.badges
        .where((badge) => badge.type == 'LEVEL')
        .firstOrNull;
    return level == null ? '非物质文化遗产' : '${level.name}非物质文化遗产';
  }

  String get _locationLabel {
    final designation = detail.designations.firstOrNull;
    final location = detail.card.location.displayText;
    if (designation == null) return location;
    final batch = designation.batchName;
    final suffix = batch == null || batch.isEmpty
        ? '${designation.year}年入选'
        : '${designation.year}年$batch入选';
    return location.isEmpty ? suffix : '$location · $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 205,
              toolbarHeight: 52,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroImage(url: detail.heroImageUrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -1),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(43, 36, 43, 95),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              detail.card.nameZh,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4C4C4C),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              (detail.card.isFavorited ?? false)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 29,
                              color: const Color(0xFF3F3F3F),
                            ),
                            onPressed: onFavoriteToggle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAD1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _levelLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFFAE6548),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 21,
                            color: Color(0xFFA3A3A3),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _locationLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          _Tab(
                            label: '工艺流程',
                            selected: !gallery,
                            onTap: () => onGalleryChanged(false),
                          ),
                          _Tab(
                            label: '传承图集',
                            selected: gallery,
                            onTap: () => onGalleryChanged(true),
                          ),
                        ],
                      ),
                      const Divider(height: 1, color: Color(0xFFB9B9B9)),
                      const SizedBox(height: 24),
                      if (gallery)
                        _Gallery(assets: detail.mediaAssets)
                      else
                        _Process(steps: detail.processSteps),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 51,
          right: 51,
          bottom: 35,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPosterTap,
              icon: const Icon(Icons.open_in_new, size: 21),
              label: const Text(
                '生成非遗海报',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9AC91),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '详情加载失败',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFFF1EDE4),
      child: Center(
        child: Icon(Icons.image_outlined, size: 42, color: AppColors.textLight),
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFB72A40) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            color: selected ? const Color(0xFFB72A40) : const Color(0xFF777777),
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class _Process extends StatelessWidget {
  const _Process({required this.steps});

  final List<ProcessStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const _EmptySection(label: '暂无工艺流程');
    }
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 21,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFB72A40),
                          width: 5,
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 3,
                        height: 126,
                        color: const Color(0xFFF1F1F1),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i].description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: Color(0xFF656565),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.assets});

  final List<MediaAsset> assets;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const _EmptySection(label: '暂无传承图集');
    }
    return Column(
      children: [
        for (var i = 0; i < assets.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 21,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFB72A40),
                          width: 5,
                        ),
                      ),
                    ),
                    if (i < assets.length - 1)
                      Container(
                        width: 3,
                        height: 125,
                        color: const Color(0xFFF1F1F1),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: _MediaImage(asset: assets[i]),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    // 视频资源同样以缩略图展示；无缩略图时回退媒体原始地址。
    final url = asset.thumbnailUrl ?? asset.url;
    const fallback = ColoredBox(
      color: Color(0xFFF5F5F5),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.textLight),
      ),
    );
    if (url.isEmpty) {
      return const SizedBox(height: 125, child: fallback);
    }
    return Image.network(
      url,
      height: 125,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const SizedBox(
              height: 125,
              child: ColoredBox(
                color: Color(0xFFF5F5F5),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
      errorBuilder: (context, error, stack) =>
          const SizedBox(height: 125, child: fallback),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textHint),
      ),
    ),
  );
}
