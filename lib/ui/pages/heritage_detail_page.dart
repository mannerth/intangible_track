import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/app_theme.dart';

class HeritageDetailPage extends StatefulWidget {
  const HeritageDetailPage({super.key, required this.title});
  final String title;

  @override
  State<HeritageDetailPage> createState() => _HeritageDetailPageState();
}

class _HeritageDetailPageState extends State<HeritageDetailPage> {
  bool _gallery = false;
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.title == '非遗详情' ? '汉绣' : widget.title;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
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
                  background: Image.asset(
                    'assets/hanxiu/detail_process.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
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
                                title,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4C4C4C),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 29,
                                color: const Color(0xFF3F3F3F),
                              ),
                              onPressed: () =>
                                  setState(() => _favorite = !_favorite),
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
                          child: const Text(
                            '国家级非物质文化遗产',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFAE6548),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 21,
                              color: Color(0xFFA3A3A3),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '湖北省武汉市 · 2008年第二次入选',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            _Tab(
                              label: '工艺流程',
                              selected: !_gallery,
                              onTap: () => setState(() => _gallery = false),
                            ),
                            _Tab(
                              label: '传承图集',
                              selected: _gallery,
                              onTap: () => setState(() => _gallery = true),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFB9B9B9)),
                        const SizedBox(height: 24),
                        _gallery ? const _Gallery() : const _Process(),
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
                onPressed: () =>
                    context.pushNamed('heritagePoster', extra: title),
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
      ),
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
  const _Process();
  static const steps = [
    ('第一步 设计与上稿', '这是刺绣前的准备工作。首先需要在纸上设计好图案，然后将设计好的纹样通过复写纸等方式描摹到绣布上，作为刺绣的蓝本。'),
    ('第二步 上绷', '将描好图案的绣布紧紧绷在绣花绷（如圆绷或绷架）上。确保绣布绷紧、平整，这是保证刺绣质量的基础。'),
    ('第三步 配线与劈丝', '根据图案的配色需要准备绣线。汉绣用线讲究，为了绣制精细部分，常常需要将一根绣线“劈”成更细的几股。'),
  ];
  @override
  Widget build(BuildContext context) => Column(
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
                      steps[i].$1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      steps[i].$2,
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

class _Gallery extends StatelessWidget {
  const _Gallery();

  static const _images = [
    'assets/hanxiu/detail_gallery.png',
    'assets/hanxiu/detail_process.png',
    'assets/hanxiu/poster.png',
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < _images.length; i++)
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
                  if (i < _images.length - 1)
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
                  child: Image.asset(
                    _images[i],
                    height: 125,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
    ],
  );
}
