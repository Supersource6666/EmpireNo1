import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_item.dart';

class FoodStorageService {
  static const String _fileName = 'custom_foods.txt';
  static const String _defaultFoodsAsset = 'assets/foods.txt';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  // 解析美食数据（CSV 格式：名称,emoji,类别,描述）
  static List<FoodItem> _parseFoodData(String data) {
    final List<FoodItem> foods = [];
    final lines = data.split('\n');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(',');
      if (parts.length >= 4) {
        foods.add(FoodItem(
          name: parts[0].trim(),
          emoji: parts[1].trim(),
          category: parts[2].trim(),
          description: parts[3].trim(),
        ));
      }
    }
    
    return foods;
  }

  // 从 assets 加载默认美食列表
  static Future<List<FoodItem>> loadDefaultFoods() async {
    try {
      final String data = await rootBundle.loadString(_defaultFoodsAsset);
      return _parseFoodData(data);
    } catch (e) {
      print('Error loading default foods from assets: $e');
      // 如果加载失败，返回硬编码的默认数据
      return _getHardcodedDefaultFoods();
    }
  }

  // 硬编码的默认美食（备用方案）
  static List<FoodItem> _getHardcodedDefaultFoods() {
    return [
      FoodItem(
        name: '红烧肉',
        emoji: '🍖',
        category: '猪肉',
        description: '传统家常菜，肥而不腻',
      ),
      FoodItem(
        name: '宫保鸡丁',
        emoji: '🍗',
        category: '鸡肉',
        description: '香辣可口的经典川菜',
      ),
      FoodItem(
        name: '鱼香肉丝',
        emoji: '🍲',
        category: '综合',
        description: '酸辣适中，回味无穷',
      ),
      FoodItem(
        name: '麻婆豆腐',
        emoji: '🌶️',
        category: '豆制品',
        description: '麻、辣、烫、香、嫩的完美结合',
      ),
    ];
  }

  // 从文件读取自定义美食列表
  static Future<List<FoodItem>> loadCustomFoodsFromFile() async {
    try {
      final file = await _getFile();
      if (!file.existsSync()) {
        return [];
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }

      final lines = contents.split('\n');
      final foods = <FoodItem>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final food = FoodItem.fromString(line);
        if (food != null) {
          foods.add(food);
        }
      }

      return foods;
    } catch (e) {
      print('Error loading custom foods from file: $e');
      return [];
    }
  }

  // 获取所有美食列表（默认 + 自定义）
  static Future<List<FoodItem>> getAllFoods() async {
    final defaultFoods = await loadDefaultFoods();
    final customFoods = await loadCustomFoodsFromFile();
    return [...defaultFoods, ...customFoods];
  }

  // 保存自定义美食列表到文件
  static Future<void> saveCustomFoodsToFile(List<FoodItem> foods) async {
    try {
      final file = await _getFile();
      final contents = foods.map((food) => food.toString()).join('\n');
      await file.writeAsString(contents);
    } catch (e) {
      print('Error saving custom foods to file: $e');
      throw e;
    }
  }

  // 添加单个自定义美食
  static Future<void> addCustomFood(FoodItem food) async {
    try {
      final foods = await loadCustomFoodsFromFile();
      foods.add(food);
      await saveCustomFoodsToFile(foods);
    } catch (e) {
      print('Error adding custom food: $e');
      throw e;
    }
  }

  // 删除自定义美食（按索引）
  static Future<void> deleteCustomFood(int index) async {
    try {
      final foods = await loadCustomFoodsFromFile();
      if (index >= 0 && index < foods.length) {
        foods.removeAt(index);
        await saveCustomFoodsToFile(foods);
      }
    } catch (e) {
      print('Error deleting custom food: $e');
      throw e;
    }
  }

  // 删除自定义美食（按名称）
  static Future<void> deleteCustomFoodByName(String name) async {
    try {
      final foods = await loadCustomFoodsFromFile();
      foods.removeWhere((food) => food.name == name);
      await saveCustomFoodsToFile(foods);
    } catch (e) {
      print('Error deleting custom food by name: $e');
      throw e;
    }
  }

  // 获取自定义美食列表
  static Future<List<FoodItem>> getCustomFoods() async {
    return loadCustomFoodsFromFile();
  }

  // 保存自定义美食（别名方法）
  static Future<void> saveCustomFood(FoodItem food) async {
    return addCustomFood(food);
  }

  // 清空所有自定义美食
  static Future<void> clearCustomFoods() async {
    try {
      final file = await _getFile();
      await file.writeAsString('');
    } catch (e) {
      print('Error clearing custom foods: $e');
      throw e;
    }
  }

  // 从文件读取美食列表（兼容旧接口）
  static Future<List<FoodItem>> loadFoodsFromFile() async {
    return loadCustomFoodsFromFile();
  }

  // 保存美食列表到文件（兼容旧接口）
  static Future<void> saveFoodsToFile(List<FoodItem> foods) async {
    return saveCustomFoodsToFile(foods);
  }

  // 添加单个美食（兼容旧接口）
  static Future<void> addFood(FoodItem food) async {
    return addCustomFood(food);
  }

  // 删除美食（兼容旧接口）
  static Future<void> deleteFood(int index) async {
    return deleteCustomFood(index);
  }
}


// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:path_provider/path_provider.dart';
// import '../models/food_item.dart';

// class FoodStorageService {
//   static const String _customFoodsKey = 'custom_foods';
//   static const String _customFoodsFileName = 'custom_foods.txt';
//   static SharedPreferences? _prefs;

//   // 初始化
//   static Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();
//   }

//   // 获取自定义美食文件路径
//   static Future<String> _getCustomFoodsFilePath() async {
//     final directory = await getApplicationDocumentsDirectory();
//     return '${directory.path}/$_customFoodsFileName';
//   }

//   // 从 assets 加载默认美食列表
//   static Future<List<FoodItem>> loadDefaultFoods() async {
//     try {
//       final String data = await rootBundle.loadString('assets/foods.txt');
//       return _parseFoodData(data);
//     } catch (e) {
//       // 如果加载失败，返回硬编码的默认数据
//       return FoodData.foods;
//     }
//   }

//   // 解析食物数据
//   static List<FoodItem> _parseFoodData(String data) {
//     final List<FoodItem> foods = [];
//     final lines = data.split('\n');
    
//     for (var line in lines) {
//       line = line.trim();
//       if (line.isEmpty) continue;
      
//       final parts = line.split(',');
//       if (parts.length >= 4) {
//         foods.add(FoodItem(
//           name: parts[0].trim(),
//           emoji: parts[1].trim(),
//           category: parts[2].trim(),
//           description: parts[3].trim(),
//         ));
//       }
//     }
    
//     return foods;
//   }

//   // 获取自定义美食列表（从txt文件读取）
//   static Future<List<FoodItem>> getCustomFoods() async {
//     try {
//       final filePath = await _getCustomFoodsFilePath();
//       final file = File(filePath);
      
//       if (!await file.exists()) {
//         return [];
//       }
      
//       final data = await file.readAsString();
//       return _parseFoodData(data);
//     } catch (e) {
//       print('读取自定义美食失败: $e');
//       return [];
//     }
//   }

//   // 保存自定义美食（写入txt文件）
//   static Future<bool> saveCustomFood(FoodItem food) async {
//     try {
//       final customFoods = await getCustomFoods();
//       customFoods.add(food);
//       return await _saveCustomFoodsToFile(customFoods);
//     } catch (e) {
//       print('保存自定义美食失败: $e');
//       return false;
//     }
//   }

//   // 将自定义美食列表写入文件
//   static Future<bool> _saveCustomFoodsToFile(List<FoodItem> foods) async {
//     try {
//       final filePath = await _getCustomFoodsFilePath();
//       final file = File(filePath);
      
//       final buffer = StringBuffer();
//       for (var food in foods) {
//         buffer.writeln('${food.name},${food.emoji},${food.category},${food.description}');
//       }
      
//       await file.writeAsString(buffer.toString());
//       return true;
//     } catch (e) {
//       print('写入文件失败: $e');
//       return false;
//     }
//   }

//   // 删除自定义美食（从txt文件删除）
//   static Future<bool> deleteCustomFood(int index) async {
//     try {
//       final customFoods = await getCustomFoods();
//       if (index >= 0 && index < customFoods.length) {
//         customFoods.removeAt(index);
//         return await _saveCustomFoodsToFile(customFoods);
//       }
//       return false;
//     } catch (e) {
//       print('删除自定义美食失败: $e');
//       return false;
//     }
//   }

//   // 获取所有美食（默认 + 自定义）
//   static Future<List<FoodItem>> getAllFoods() async {
//     final defaultFoods = await loadDefaultFoods();
//     final customFoods = await getCustomFoods();
//     return [...defaultFoods, ...customFoods];
//   }

//   // 导出美食列表到文件
//   static Future<String> exportFoods(List<FoodItem> foods) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/foods_export.txt');
    
//     final buffer = StringBuffer();
//     for (var food in foods) {
//       buffer.writeln('${food.name},${food.emoji},${food.category},${food.description}');
//     }
    
//     await file.writeAsString(buffer.toString());
//     return file.path;
//   }

//   // 从文件导入美食列表
//   static Future<List<FoodItem>> importFoods(String filePath) async {
//     final file = File(filePath);
//     if (!await file.exists()) return [];
    
//     final data = await file.readAsString();
//     return _parseFoodData(data);
//   }
// }
