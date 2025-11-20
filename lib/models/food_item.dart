class FoodItem {
  final String name;
  final String emoji;
  final String category;
  final String description;

  FoodItem({
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
  });
}

// 预定义的美食数据
class FoodData {
  static final List<FoodItem> foods = [
    FoodItem(
      name: '火锅',
      emoji: '🍲',
      category: '中餐',
      description: '麻辣鲜香，热气腾腾',
    ),
    FoodItem(
      name: '寿司',
      emoji: '🍣',
      category: '日料',
      description: '新鲜美味，精致可口',
    ),
    FoodItem(
      name: '披萨',
      emoji: '🍕',
      category: '西餐',
      description: '奶酪拉丝，香脆可口',
    ),
    FoodItem(
      name: '拉面',
      emoji: '🍜',
      category: '日料',
      description: '汤浓面劲，回味无穷',
    ),
    FoodItem(
      name: '汉堡',
      emoji: '🍔',
      category: '快餐',
      description: '肉汁四溢，满足感满满',
    ),
    FoodItem(
      name: '炸鸡',
      emoji: '🍗',
      category: '快餐',
      description: '外酥里嫩，香气扑鼻',
    ),
    FoodItem(
      name: '烤肉',
      emoji: '🥩',
      category: '烧烤',
      description: '火候刚好，鲜嫩多汁',
    ),
    FoodItem(
      name: '意面',
      emoji: '🍝',
      category: '西餐',
      description: '酱汁浓郁，口感顺滑',
    ),
    FoodItem(
      name: '咖喱饭',
      emoji: '🍛',
      category: '亚洲菜',
      description: '香辣浓郁，暖心暖胃',
    ),
    FoodItem(
      name: '炒饭',
      emoji: '🍚',
      category: '中餐',
      description: '粒粒分明，香气四溢',
    ),
    FoodItem(
      name: '饺子',
      emoji: '🥟',
      category: '中餐',
      description: '皮薄馅大，鲜美多汁',
    ),
    FoodItem(
      name: '沙拉',
      emoji: '🥗',
      category: '轻食',
      description: '清爽健康，营养丰富',
    ),
  ];
}
