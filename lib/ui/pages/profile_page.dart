import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _menuItems = [
    ('浏览记录', Icons.history),
    ('编辑资料', Icons.edit_outlined),
    ('联系我们', Icons.headset_mic_outlined),
    ('语言', Icons.language_outlined),
    ('退出登录', Icons.logout_outlined),
    ('注销账号', Icons.person_off_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 顶部信息区
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: AppColors.header,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset('assets/山.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                // 头像
                Positioned(
                  left: 21,
                  top: 76,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const Icon(
                      Icons.person,
                      size: 44,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const Positioned(
                  left: 117,
                  top: 97,
                  child: Text(
                    '天凉被破王',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const Positioned(
                  left: 117,
                  top: 125,
                  child: Text(
                    '这个人很神秘，什么都没有留下',
                    style: TextStyle(fontSize: 14, color: AppColors.accent),
                  ),
                ),
                // 收藏 / 生成海报 卡片
                Positioned(
                  left: 16,
                  top: 182,
                  right: 16,
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _EntryTile(
                            icon: Icons.favorite_border,
                            title: '收藏',
                            subtitle: '查看收藏的非遗或地区',
                            onTap: () => context.pushNamed('favorites'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EntryTile(
                            icon: Icons.auto_awesome_outlined,
                            title: '生成海报',
                            subtitle: '查看所有已生成海报',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < _menuItems.length; i++) ...[
            _MenuRow(item: _menuItems[i]),
            if (i < _menuItems.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final (String, IconData) item;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = item;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.textHint),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
        ],
      ),
    );
  }
}
