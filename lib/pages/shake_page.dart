import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class ShakePage extends StatefulWidget {
  const ShakePage({super.key});

  @override
  State<ShakePage> createState() => _ShakePageState();
}

class _ShakePageState extends State<ShakePage> with TickerProviderStateMixin {
  List<FoodItem> foods = [];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  bool isShaking = false;
  bool hasResult = false;
  int selectedIndex = 0;
  bool isLoading = true;
  
  late AnimationController _shakeController;
  late AnimationController _resultController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  
  double _shakeThreshold = 15.0; // 摇动阈值
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    _loadFoods();
    
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadFoods() async {
    final allFoods = await FoodStorageService.getAllFoods();
    setState(() {
      foods = allFoods;
      isLoading = false;
    });
    _startListening();
  }

  void _startListening() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _detectShake(event.x, event.y, event.z);
      },
    );
  }

  void _detectShake(double x, double y, double z) {
    // 计算加速度的总和
    double acceleration = sqrt(x * x + y * y + z * z);
    
    // 如果加速度超过阈值且不在冷却时间内
    if (acceleration > _shakeThreshold && !isShaking && !hasResult) {
      final now = DateTime.now();
      if (_lastShakeTime == null || 
          now.difference(_lastShakeTime!).inMilliseconds > 1000) {
        _lastShakeTime = now;
        _onShakeDetected();
      }
    }
  }

  void _onShakeDetected() {
    setState(() {
      isShaking = true;
    });
    
    FeedbackService.playSpinSound();
    FeedbackService.shakeVibrate();
    
    // 播放摇动动画
    _shakeController.repeat(reverse: true);
    
    // 2秒后显示结果
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isShaking = false;
        hasResult = true;
        selectedIndex = Random().nextInt(foods.length);
      });
      
      _shakeController.stop();
      _shakeController.reset();
      FeedbackService.playSuccessSound();
      FeedbackService.successVibrate();
      _resultController.forward();
    });
  }

  void _reset() {
    setState(() {
      hasResult = false;
      selectedIndex = 0;
    });
    _resultController.reset();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _shakeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('摇一摇抽奖'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade200, Colors.deepOrange.shade400],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!hasResult) ...[
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        sin(_shakeAnimation.value) * 10,
                        cos(_shakeAnimation.value) * 10,
                      ),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.phone_iphone,
                          size: 100,
                          color: isShaking ? Colors.orange : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  isShaking ? '正在摇动中...' : '摇一摇手机',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                if (!isShaking)
                  const Text(
                    '用力摇动手机开始抽奖',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
              ] else ...[
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎉 抽中了！',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          foods[selectedIndex].emoji,
                          style: const TextStyle(fontSize: 100),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          foods[selectedIndex].name,
                          style: const TextStyle(
                            fontSize: 36,
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          foods[selectedIndex].description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '再摇一次',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
