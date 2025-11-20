import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class SlotMachinePage extends StatefulWidget {
  const SlotMachinePage({super.key});

  @override
  State<SlotMachinePage> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends State<SlotMachinePage> {
  List<FoodItem> foods = [];
  
  late FixedExtentScrollController _controller1;
  late FixedExtentScrollController _controller2;
  late FixedExtentScrollController _controller3;

  bool isSpinning = false;
  List<int> results = [0, 0, 0];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller1 = FixedExtentScrollController();
    _controller2 = FixedExtentScrollController();
    _controller3 = FixedExtentScrollController();
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
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (isSpinning) return;

    FeedbackService.playSpinSound();
    FeedbackService.mediumVibrate();

    setState(() => isSpinning = true);

    // 生成随机结果
    results = [
      Random().nextInt(foods.length),
      Random().nextInt(foods.length),
      Random().nextInt(foods.length),
    ];

    // 第一个轮子：快速滚动后停止
    _animateWheel(_controller1, results[0], 2000);

    // 第二个轮子：延迟0.5秒后开始
    await Future.delayed(const Duration(milliseconds: 500));
    _animateWheel(_controller2, results[1], 2000);

    // 第三个轮子：延迟1秒后开始
    await Future.delayed(const Duration(milliseconds: 500));
    _animateWheel(_controller3, results[2], 2000);

    // 等待所有轮子停止
    await Future.delayed(const Duration(milliseconds: 2500));
    
    setState(() => isSpinning = false);
    FeedbackService.playSuccessSound();
    FeedbackService.successVibrate();
    _showResultDialog();
  }

  void _animateWheel(FixedExtentScrollController controller, int targetIndex, int duration) {
    // 多转几圈增加效果
    final int spins = 20;
    final int targetPosition = spins * foods.length + targetIndex;

    controller.animateToItem(
      targetPosition,
      duration: Duration(milliseconds: duration),
      curve: Curves.easeOutCubic,
    );
  }

  void _showResultDialog() {
    // 检查是否有相同的食物
    final hasMatch = results[0] == results[1] && results[1] == results[2];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasMatch ? '🎊 超级幸运！' : '🎉 结果出炉！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMatch) ...[
              const Text(
                '三个相同！',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: results.map((index) {
                return Column(
                  children: [
                    Text(foods[index].emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(foods[index].name, style: const TextStyle(fontSize: 16)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (!hasMatch)
              Text(
                '今天推荐：${foods[results[1]].name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(FixedExtentScrollController controller) {
    return Container(
      width: 100,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 3),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 80,
        physics: const NeverScrollableScrollPhysics(),
        diameterRatio: 1.5,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: foods.map((food) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(food.emoji, style: const TextStyle(fontSize: 32)),
                  Text(
                    food.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('老虎机抽奖'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎰 老虎机',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              '今天吃什么？',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 选中指示器
                  Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.yellow, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.yellow.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 三个轮子
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWheel(_controller1),
                      const SizedBox(width: 10),
                      _buildWheel(_controller2),
                      const SizedBox(width: 10),
                      _buildWheel(_controller3),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: isSpinning ? null : _spin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                backgroundColor: Colors.amber,
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              child: Text(isSpinning ? '抽奖中...' : '🎲 开始'),
            ),
          ],
        ),
      ),
    );
  }
}
