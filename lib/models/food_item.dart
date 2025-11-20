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

  // 转换为字符串格式（用于保存到文件）
  @override
  String toString() {
    return '$emoji|$name|$category|$description';
  }

  // 从字符串格式解析（用于从文件读取）
  static FoodItem? fromString(String line) {
    try {
      final parts = line.split('|');
      if (parts.length == 4) {
        return FoodItem(
          emoji: parts[0].trim(),
          name: parts[1].trim(),
          category: parts[2].trim(),
          description: parts[3].trim(),
        );
      }
    } catch (e) {
      print('Error parsing food item: $e');
    }
    return null;
  }

  // JSON 序列化（如需要）
  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'name': name,
      'category': category,
      'description': description,
    };
  }

  // JSON 反序列化（如需要）
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      emoji: json['emoji'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
    );
  }
}

// class FoodItem {
//   final String name;
//   final String emoji;
//   final String category;
//   final String description;

//   FoodItem({
//     required this.name,
//     required this.emoji,
//     required this.category,
//     required this.description,
//   });
// }

// // 预定义的美食数据
// class FoodData {
//   static final List<FoodItem> foods = [
//     FoodItem(
//       name: '火锅',
//       emoji: '🍲',
//       category: '中餐',
//       description: '麻辣鲜香，热气腾腾',
//     ),
//     FoodItem(
//       name: '寿司',
//       emoji: '🍣',
//       category: '日料',
//       description: '新鲜美味，精致可口',
//     ),
//     FoodItem(
//       name: '披萨',
//       emoji: '🍕',
//       category: '西餐',
//       description: '奶酪拉丝，香脆可口',
//     ),
//     FoodItem(
//       name: '拉面',
//       emoji: '🍜',
//       category: '日料',
//       description: '汤浓面劲，回味无穷',
//     ),
//     FoodItem(
//       name: '汉堡',
//       emoji: '🍔',
//       category: '快餐',
//       description: '肉汁四溢，满足感满满',
//     ),
//     FoodItem(
//       name: '炸鸡',
//       emoji: '🍗',
//       category: '快餐',
//       description: '外酥里嫩，香气扑鼻',
//     ),
//     FoodItem(
//       name: '烤肉',
//       emoji: '🥩',
//       category: '烧烤',
//       description: '火候刚好，鲜嫩多汁',
//     ),
//     FoodItem(
//       name: '意面',
//       emoji: '🍝',
//       category: '西餐',
//       description: '酱汁浓郁，口感顺滑',
//     ),
//     FoodItem(
//       name: '咖喱饭',
//       emoji: '🍛',
//       category: '亚洲菜',
//       description: '香辣浓郁，暖心暖胃',
//     ),
//     FoodItem(
//       name: '炒饭',
//       emoji: '🍚',
//       category: '中餐',
//       description: '粒粒分明，香气四溢',
//     ),
//     FoodItem(
//       name: '饺子',
//       emoji: '🥟',
//       category: '中餐',
//       description: '皮薄馅大，鲜美多汁',
//     ),
//     FoodItem(
//       name: '沙拉',
//       emoji: '🥗',
//       category: '轻食',
//       description: '清爽健康，营养丰富',
//     ),
//   ];
// }
