import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/app_theme.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets/search_header.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyTopicsProvider);
    final hot = ref.watch(hotTopicsProvider);

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
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 1),
                    itemCount: daily.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _DailyCard(topic: daily[index], index: index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 36),
                const _SectionTitle(title: '热门话题'),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 104 / 149,
                  ),
                  itemCount: hot.length,
                  itemBuilder: (context, index) {
                    return _HotTopicCard(topic: hot[index], index: index);
                  },
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

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.topic, required this.index});

  final HeritageTopic topic;
  final int index;

  static const _gradients = [
    [Color(0xFFD27650), Color(0xFFE8A87C)],
    [Color(0xFF6E8B6E), Color(0xFFA8BCA0)],
    [Color(0xFF7A6C9E), Color(0xFFB3A7CC)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % _gradients.length];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.landscape_outlined,
              size: 140,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  topic.tagline,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotTopicCard extends StatelessWidget {
  const _HotTopicCard({required this.topic, required this.index});

  final HeritageTopic topic;
  final int index;

  static const _gradients = [
    [Color(0xFFB0603F), Color(0xFFD9A066)],
    [Color(0xFF5C7A6C), Color(0xFF93B5A0)],
    [Color(0xFF6D5A8E), Color(0xFFA08CBE)],
    [Color(0xFFB0783F), Color(0xFFE0B57C)],
    [Color(0xFF7A8E5C), Color(0xFFB5C793)],
    [Color(0xFF8E5C76), Color(0xFFC793AE)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      padding: const EdgeInsets.all(10),
      alignment: Alignment.topLeft,
      child: Text(
        topic.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
