/// 省份及其代表非遗项目
class Province {
  const Province({required this.name, required this.items});

  final String name;
  final List<String> items;
}

/// 非遗话题卡片（每日推送 / 热门话题）
class HeritageTopic {
  const HeritageTopic({required this.title, required this.tagline});

  final String title;
  final String tagline;
}

const List<Province> kProvinces = [
  Province(name: '湖北省', items: ['汉绣', '汉剧']),
  Province(name: '吉林省', items: ['满族剪纸', '黄龙戏']),
];

const List<HeritageTopic> kDailyTopics = [
  HeritageTopic(title: '非遗 | 苏绣', tagline: '丝线绣韶华，江山入我画'),
  HeritageTopic(title: '非遗 | 点茶', tagline: '碾茶凝雪色，击盏续宋风'),
  HeritageTopic(title: '非遗 | 傩戏', tagline: '假面酬神祀，傩舞祈岁安'),
];

const List<HeritageTopic> kHotTopics = [
  HeritageTopic(title: '非遗 | 京剧', tagline: '粉墨承千古，弦歌唱九州'),
  HeritageTopic(title: '非遗 | 蜡染', tagline: '染缬凝古韵，素布绘山川'),
  HeritageTopic(title: '非遗 | 皮影戏', tagline: '灯影演千古，皮偶叙悲欢'),
  HeritageTopic(title: '非遗 | 苏绣', tagline: '丝线绣韶华，江山入我画'),
  HeritageTopic(title: '非遗 | 点茶', tagline: '碾茶凝雪色，击盏续宋风'),
  HeritageTopic(title: '非遗 | 傩戏', tagline: '假面酬神祀，傩舞祈岁安'),
];

/// 省份名录中的非遗条目
class HeritageEntry {
  const HeritageEntry({
    required this.title,
    required this.category,
    required this.level,
    required this.description,
  });

  final String title;
  final String category;
  final String level;
  final String description;
}

const List<HeritageEntry> kHubeiEntries = [
  HeritageEntry(
    title: '汉绣',
    category: '民间传统美术',
    level: '国家级',
    description: '汉绣是源于战国时期的楚绣，历史悠久。其艺术特色鲜明，以色彩浓艳、构思大胆而著称，是湖北最具代表性的传统美术之一。',
  ),
  HeritageEntry(
    title: '汉绣',
    category: '民间传统美术',
    level: '世界级',
    description: '汉绣是源于战国时期的楚绣，历史悠久。其艺术特色鲜明，以色彩浓艳、构思大胆而著称，是湖北最具代表性的传统美术之一。',
  ),
  HeritageEntry(
    title: '汉绣',
    category: '民间传统美术',
    level: '省级重点',
    description: '汉绣讲究“铺、平、织、间”的针法，绣面浓丽繁复，题材多取自荆楚风物与民间故事，地域特色浓郁。',
  ),
];

const List<HeritageEntry> kJilinEntries = [
  HeritageEntry(
    title: '满族剪纸',
    category: '民间传统美术',
    level: '国家级',
    description: '满族剪纸起源于满族所信奉的萨满教，最早用于祭祀。长白山满族剪纸造型质朴，多用折叠剪法表现人、兽与自然崇拜。',
  ),
  HeritageEntry(
    title: '满族剪纸',
    category: '民间传统美术',
    level: '世界级',
    description: '满族剪纸起源于满族所信奉的萨满教，最早用于祭祀。长白山满族剪纸造型质朴，多用折叠剪法表现人、兽与自然崇拜。',
  ),
  HeritageEntry(
    title: '满族剪纸',
    category: '民间传统美术',
    level: '省级重点',
    description: '满族剪纸以萨满祭祀纹样为根，剪纸语言粗犷率真，常见嬷嬷人、生命树等题材，承载着关东民俗记忆。',
  ),
];
