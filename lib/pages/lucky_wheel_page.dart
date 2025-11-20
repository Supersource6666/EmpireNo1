import 'dart:math';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class LuckyWheelPage extends StatefulWidget {
  const LuckyWheelPage({super.key});

  @override
  State<LuckyWheelPage> createState() => _LuckyWheelPageState();
}

class _LuckyWheelPageState extends State<LuckyWheelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;
  int selectedIndex = 0;
  bool isSpinning = false;
  List<FoodItem> foods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
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
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (isSpinning) return;

    FeedbackService.playSpinSound();
    FeedbackService.mediumVibrate();

    setState(() {
      isSpinning = true;
      selectedIndex = Random().nextInt(foods.length);
    });

    final double targetRotation = 5 * 2 * pi + (selectedIndex * 2 * pi / foods.length);
    _animation = Tween<double>(
      begin: 0,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _controller.forward(from: 0).then((_) {
      setState(() => isSpinning = false);
      FeedbackService.playSuccessSound();
      FeedbackService.successVibrate();
      _showResultDialog();
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 恭喜！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              foods[selectedIndex].emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              foods[selectedIndex].name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(foods[selectedIndex].description),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大转盘抽奖'),
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _animation!,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation!.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: WheelPainter(foods: foods),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // 指针
            const Icon(
              Icons.arrow_drop_up,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isSpinning ? null : _spin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: Text(isSpinning ? '转动中...' : '开始抽奖'),
            ),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<FoodItem> foods;

  WheelPainter({required this.foods});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectionAngle = 2 * pi / foods.length;

    // 颜色列表
    final colors = [
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.yellow.shade300,
      Colors.green.shade300,
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
    ];

    // 绘制扇形
    for (int i = 0; i < foods.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectionAngle - pi / 2,
        sectionAngle,
        true,
        paint,
      );

      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectionAngle - pi / 2,
        sectionAngle,
        true,
        borderPaint,
      );

      // 绘制文字
      final textAngle = i * sectionAngle + sectionAngle / 2 - pi / 2;
      final textX = center.dx + cos(textAngle) * radius * 0.6;
      final textY = center.dy + sin(textAngle) * radius * 0.6;

      final textSpan = TextSpan(
        text: '${foods[i].emoji}\n${foods[i].name}',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // 绘制中心圆
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 30, centerPaint);
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) => false;
}
