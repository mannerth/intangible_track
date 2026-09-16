import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/api_models.dart';
import '../../api/providers.dart';
import '../../common/app_theme.dart';

/// 海报预览页：POST /me/posters 生成（或复用）后展示。
class HeritagePosterPage extends ConsumerWidget {
  const HeritagePosterPage({super.key, required this.heritageId});

  final String heritageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creation = ref.watch(posterCreationProvider(heritageId));
    final title = creation.value?.poster.heritageItem.nameZh ?? '非遗';

    return Scaffold(
      backgroundColor: AppColors.header,
      appBar: AppBar(
        backgroundColor: AppColors.header,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('$title 非遗海报'),
      ),
      body: creation.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, stack) => _PosterError(
          onRetry: () => ref.invalidate(posterCreationProvider(heritageId)),
        ),
        data: (value) => _PosterBody(poster: value.poster),
      ),
    );
  }
}

class _PosterError extends StatelessWidget {
  const _PosterError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 14),
          const Text(
            '海报生成失败',
            style: TextStyle(fontSize: 15, color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          const Text(
            '请确认已登录，且该非遗条目已配置海报素材。',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _PosterBody extends StatelessWidget {
  const _PosterBody({required this.poster});

  final Poster poster;

  @override
  Widget build(BuildContext context) {
    final url = poster.imageUrl ?? poster.thumbnailUrl;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 20, 44, 28),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _PosterImage(url: url),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _notify(context, '长按海报即可保存到本地'),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('保存非遗海报'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _notify(context, '系统分享尚未接入'),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('分享非遗海报'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    debugPrint(url);
    const fallback = ColoredBox(
      color: Colors.white,
      child: Center(
        child: Icon(Icons.image_outlined, size: 42, color: AppColors.textLight),
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}
