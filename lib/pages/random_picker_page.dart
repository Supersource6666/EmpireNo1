import 'dart:math';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class RandomPickerPage extends StatefulWidget {
  const RandomPickerPage({super.key});

  @override
  State<RandomPickerPage> createState() => _RandomPickerPageState();
}

class _RandomPickerPageState extends State<RandomPickerPage>
    with SingleTickerProviderStateMixin {
  List<FoodItem> foods = [];
  late FixedExtentScrollController _scrollController;
  late AnimationController _animationController;
  
  bool isSpinning = false;
  int selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final allFoods = await FoodStorageService.getAllFoods();
    setState(() {
      foods = allFoods;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startPicking() async {
    if (isSpinning) return;

    FeedbackService.playSpinSound();
    FeedbackService.mediumVibrate();

    setState(() {
      isSpinning = true;
      selectedIndex = Random().nextInt(foods.length);
    });

    // 多转几圈增加效果
    final int spins = 30;
    final int targetPosition = spins * foods.length + selectedIndex;

    await _scrollController.animateToItem(
      targetPosition,
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeOutCubic,
    );

    setState(() => isSpinning = false);
    FeedbackService.playSuccessSound();
    FeedbackService.successVibrate();
    _showResultDialog();
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 抽中了！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              foods[selectedIndex].emoji,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            Text(
              foods[selectedIndex].name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                foods[selectedIndex].category,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              foods[selectedIndex].description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startPicking();
            },
            child: const Text('再抽一次'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('随机选择'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '今天吃什么？',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Container(
              height: 400,
              width: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade200, Colors.blue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 选中区域指示器
                  Center(
                    child: Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.yellow, width: 4),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.yellow.withOpacity(0.2),
                      ),
                    ),
                  ),
                  // 滚动列表
                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 100,
                    diameterRatio: 1.2,
                    physics: const NeverScrollableScrollPhysics(),
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: foods.map((food) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  food.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: isSpinning ? null : _startPicking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(isSpinning ? '抽取中...' : '🎲 随机抽取'),
            ),
            const SizedBox(height: 20),
            if (!isSpinning)
              Text(
                '共有 ${foods.length} 种美食可选',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
