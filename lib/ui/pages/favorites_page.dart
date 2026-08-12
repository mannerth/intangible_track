import 'package:flutter/material.dart';

import '../../common/app_theme.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 56,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有收藏内容',
              style: TextStyle(fontSize: 16, color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            Text(
              '收藏喜欢的非遗或地区，方便以后快速查看',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
