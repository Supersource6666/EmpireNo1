import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_item.dart';

class FoodStorageService {
  static const String _customFoodsKey = 'custom_foods';
  static const String _customFoodsFileName = 'custom_foods.txt';
  static SharedPreferences? _prefs;

  // 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 获取自定义美食文件路径
  static Future<String> _getCustomFoodsFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_customFoodsFileName';
  }

  // 从 assets 加载默认美食列表
  static Future<List<FoodItem>> loadDefaultFoods() async {
    try {
      final String data = await rootBundle.loadString('assets/foods.txt');
      return _parseFoodData(data);
    } catch (e) {
      // 如果加载失败，返回硬编码的默认数据
      return FoodData.foods;
    }
  }

  // 解析食物数据
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

  // 获取自定义美食列表（从txt文件读取）
  static Future<List<FoodItem>> getCustomFoods() async {
    try {
      final filePath = await _getCustomFoodsFilePath();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return [];
      }
      
      final data = await file.readAsString();
      return _parseFoodData(data);
    } catch (e) {
      print('读取自定义美食失败: $e');
      return [];
    }
  }

  // 保存自定义美食（写入txt文件）
  static Future<bool> saveCustomFood(FoodItem food) async {
    try {
      final customFoods = await getCustomFoods();
      customFoods.add(food);
      return await _saveCustomFoodsToFile(customFoods);
    } catch (e) {
      print('保存自定义美食失败: $e');
      return false;
    }
  }

  // 将自定义美食列表写入文件
  static Future<bool> _saveCustomFoodsToFile(List<FoodItem> foods) async {
    try {
      final filePath = await _getCustomFoodsFilePath();
      final file = File(filePath);
      
      final buffer = StringBuffer();
      for (var food in foods) {
        buffer.writeln('${food.name},${food.emoji},${food.category},${food.description}');
      }
      
      await file.writeAsString(buffer.toString());
      return true;
    } catch (e) {
      print('写入文件失败: $e');
      return false;
    }
  }

  // 删除自定义美食（从txt文件删除）
  static Future<bool> deleteCustomFood(int index) async {
    try {
      final customFoods = await getCustomFoods();
      if (index >= 0 && index < customFoods.length) {
        customFoods.removeAt(index);
        return await _saveCustomFoodsToFile(customFoods);
      }
      return false;
    } catch (e) {
      print('删除自定义美食失败: $e');
      return false;
    }
  }

  // 获取所有美食（默认 + 自定义）
  static Future<List<FoodItem>> getAllFoods() async {
    final defaultFoods = await loadDefaultFoods();
    final customFoods = await getCustomFoods();
    return [...defaultFoods, ...customFoods];
  }

  // 导出美食列表到文件
  static Future<String> exportFoods(List<FoodItem> foods) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/foods_export.txt');
    
    final buffer = StringBuffer();
    for (var food in foods) {
      buffer.writeln('${food.name},${food.emoji},${food.category},${food.description}');
    }
    
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  // 从文件导入美食列表
  static Future<List<FoodItem>> importFoods(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];
    
    final data = await file.readAsString();
    return _parseFoodData(data);
  }
}
