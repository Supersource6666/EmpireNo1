import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class ScratchCardPage extends StatefulWidget {
  const ScratchCardPage({super.key});

  @override
  State<ScratchCardPage> createState() => _ScratchCardPageState();
}

class _ScratchCardPageState extends State<ScratchCardPage> {
  List<FoodItem> foods = [];
  final GlobalKey _scratchKey = GlobalKey();
  
  late int selectedIndex;
  List<Offset> _points = [];
  double _scratchedPercentage = 0.0;
  bool _isRevealed = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final allFoods = await FoodStorageService.getAllFoods();
    setState(() {
      foods = allFoods;
      selectedIndex = Random().nextInt(foods.length);
      isLoading = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isRevealed) return;
    
    if (_points.isEmpty || _points.length % 5 == 0) {
      FeedbackService.lightVibrate();
    }
    
    setState(() {
      RenderBox renderBox = _scratchKey.currentContext!.findRenderObject() as RenderBox;
      Offset localPosition = renderBox.globalToLocal(details.globalPosition);
      _points.add(localPosition);
      
      // 根据实际卡片尺寸和笔触大小计算刮开的百分比
      // 卡片尺寸: 320x400 = 128000 像素
      // 笔触半径: 30 (直径60)
      // 每个点大约覆盖: π * 30^2 ≈ 2827 像素
      // 估算需要的点数: 128000 / 2827 ≈ 45 个点可以覆盖100%
      // 考虑重叠，实际需要更多点，设置为150个点达到60%
      _scratchedPercentage = min(1.0, _points.length / 250);
      
      // 如果刮开超过60%，显示完整结果
      if (_scratchedPercentage > 0.6 && !_isRevealed) {
        _isRevealed = true;
        FeedbackService.playSuccessSound();
        FeedbackService.successVibrate();
        Future.delayed(const Duration(milliseconds: 300), () {
          _showResultDialog();
        });
      }
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
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: const Text('再刮一次'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      selectedIndex = Random().nextInt(foods.length);
      _points.clear();
      _scratchedPercentage = 0.0;
      _isRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('刮刮乐抽奖'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: '重新开始',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade200, Colors.orange.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '今天吃什么？',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '用手指刮开涂层查看结果',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 320,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // 底层：显示美食结果
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.orange.shade50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              foods[selectedIndex].emoji,
                              style: const TextStyle(fontSize: 80),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              foods[selectedIndex].name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                foods[selectedIndex].category,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                foods[selectedIndex].description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 顶层：涂层
                      if (!_isRevealed)
                        GestureDetector(
                          key: _scratchKey,
                          onPanUpdate: _onPanUpdate,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: ScratchPainter(
                              points: _points,
                              scratchedPercentage: _scratchedPercentage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_scratchedPercentage > 0 && !_isRevealed)
                Text(
                  '已刮开 ${(_scratchedPercentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScratchPainter extends CustomPainter {
  final List<Offset> points;
  final double scratchedPercentage;

  ScratchPainter({
    required this.points,
    required this.scratchedPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制银色涂层背景
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width, size.height),
        [Colors.grey.shade400, Colors.grey.shade600],
      );
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // 绘制"刮开有奖"文字
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '刮开\n有奖',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // 使用混合模式擦除刮过的区域
    if (points.isNotEmpty) {
      final erasePaint = Paint()
        ..color = Colors.transparent
        ..strokeWidth = 60
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.clear;

      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], erasePaint);
      }
      
      // 绘制圆点
      for (var point in points) {
        canvas.drawCircle(point, 30, erasePaint);
      }
    }
  }

  @override
  bool shouldRepaint(ScratchPainter oldDelegate) {
    return points.length != oldDelegate.points.length;
  }
}
