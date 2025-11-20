import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/feedback_service.dart';
import '../services/food_storage_service.dart';

class GridLotteryPage extends StatefulWidget {
  const GridLotteryPage({super.key});

  @override
  State<GridLotteryPage> createState() => _GridLotteryPageState();
}

class _GridLotteryPageState extends State<GridLotteryPage> {
  List<FoodItem> foods = [];
  int currentIndex = 0;
  bool isRunning = false;
  Timer? timer;
  int selectedIndex = -1;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool isClockwise = true; // true: 外向内顺时针, false: 内向外逆时针

  // 根据美食数量动态计算列数（使用开方）
  int get gridColumns {
    if (foods.isEmpty) return 3;
    return max(2, sqrt(foods.length).ceil());
  }

  // 根据美食数量动态计算行数
  int get gridRows {
    if (foods.isEmpty) return 3;
    return max(gridColumns, (foods.length / gridColumns).ceil());
  }

  // 生成完整的螺旋路径（外向内顺时针）
  List<int> get gridSequenceClockwise {
    final cols = gridColumns;
    final rows = gridRows;
    List<int> sequence = [];
    
    int top = 0, bottom = rows - 1, left = 0, right = cols - 1;

    while (top <= bottom && left <= right) {
      // 上边（从左到右）
      for (int i = left; i <= right; i++) {
        sequence.add(top * cols + i);
      }
      top++;

      // 右边（从上到下）
      for (int i = top; i <= bottom; i++) {
        sequence.add(i * cols + right);
      }
      right--;

      // 下边（从右到左）
      if (top <= bottom) {
        for (int i = right; i >= left; i--) {
          sequence.add(bottom * cols + i);
        }
        bottom--;
      }

      // 左边（从下到上）
      if (left <= right) {
        for (int i = bottom; i >= top; i--) {
          sequence.add(i * cols + left);
        }
        left++;
      }
    }

    return sequence;
  }

  // 生成完整的螺旋路径（内向外逆时针）
  List<int> get gridSequenceCounterClockwise {
    final sequence = gridSequenceClockwise;
    // 反向路径
    return sequence.reversed.toList();
  }

  // 根据方向获取路径
  List<int> get gridSequence {
    return isClockwise ? gridSequenceClockwise : gridSequenceCounterClockwise;
  }

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    try {
      final allFoods = await FoodStorageService.getAllFoods();
      setState(() {
        foods = allFoods;
        isLoading = false;
        currentIndex = 0;
        selectedIndex = -1;
      });
      // print('✅ 九宫格加载美食数量: ${foods.length}');
      // print('   列数: $gridColumns, 行数: $gridRows');
      // print('   路径长度: ${gridSequence.length}');
    } catch (e) {
      // print('❌ 加载美食失败: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFoods();
  }

  @override
  void dispose() {
    timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startLottery() {
    if (isRunning || foods.isEmpty) return;

    FeedbackService.playSpinSound();
    FeedbackService.mediumVibrate();

    setState(() {
      isRunning = true;
      currentIndex = 0;
      selectedIndex = Random().nextInt(foods.length);
      isClockwise = true; // 从外向内顺时针开始
    });

    int rounds = 0;
    const totalRounds = 3;
    const speedUpDuration = 50;
    int currentSpeed = speedUpDuration;
    final sequenceLength = gridSequence.length;

    timer = Timer.periodic(Duration(milliseconds: currentSpeed), (timer) {
      FeedbackService.lightVibrate();
      setState(() {
        currentIndex = (currentIndex + 1) % sequenceLength;
      });

      if (currentIndex == 0) {
        rounds++;
        
        // 第二圈完成后，切换为内向外逆时针
        if (rounds == 2) {
          setState(() {
            isClockwise = false;
          });
        }
      }

      if (rounds >= totalRounds - 1) {
        timer.cancel();
        _slowDown();
      }
    });
  }

  void _slowDown() {
    int currentSpeed = 100;
    int steps = 0;
    final sequenceLength = gridSequence.length;
    
    // 计算需要走的步数到达目标美食
    final targetGridIndex = _getFoodGridIndex(selectedIndex);
    final stepsNeeded = (targetGridIndex - currentIndex + sequenceLength) % sequenceLength;

    timer = Timer.periodic(Duration(milliseconds: currentSpeed), (timer) {
      if (steps >= stepsNeeded) {
        timer.cancel();
        setState(() => isRunning = false);
        FeedbackService.playSuccessSound();
        FeedbackService.successVibrate();
        _showResultDialog();
        return;
      }

      setState(() {
        currentIndex = (currentIndex + 1) % sequenceLength;
      });

      steps++;
      currentSpeed += 50;
    });
  }

  // 获取某个食物在网格序列中的位置
  int _getFoodGridIndex(int foodIndex) {
    if (foodIndex < 0 || foodIndex >= foods.length) return 0;
    if (foodIndex >= gridSequence.length) return 0;
    return gridSequence[foodIndex];
  }

  void _showResultDialog() {
    if (selectedIndex < 0 || selectedIndex >= foods.length) return;
    
    final selectedFood = foods[selectedIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 恭喜！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedFood.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              selectedFood.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              selectedFood.description,
              textAlign: TextAlign.center,
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

  Widget _buildGridItem(int gridIndex) {
    final cols = gridColumns;
    final rows = gridRows;
    final centerRow = rows ~/ 2;
    final centerCol = cols ~/ 2;
    final centerGridIndex = centerRow * cols + centerCol;
    
    // 中间位置是开始按钮
    if (gridIndex == centerGridIndex) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade400,
              Colors.deepOrange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isRunning ? null : _startLottery,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRunning ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isRunning 
                        ? '${isClockwise ? '外向内\n顺' : '内向外\n逆'}时针...' 
                        : '开始',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 找到这个网格位置在序列中的索引
    final sequenceIndex = gridSequence.indexOf(gridIndex);
    
    // 如果这个位置不在路径中或超过了美食数量，显示空白
    if (sequenceIndex == -1 || sequenceIndex >= foods.length) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
      );
    }

    final food = foods[sequenceIndex];
    final isCurrentPosition = isRunning && currentIndex == sequenceIndex;
    final isSelected = !isRunning && selectedIndex == sequenceIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isCurrentPosition
            ? Colors.yellow.shade300
            : isSelected
                ? Colors.green.shade300
                : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentPosition
              ? Colors.orange
              : isSelected
                  ? Colors.green
                  : Colors.grey.shade300,
          width: isCurrentPosition || isSelected ? 3 : 1,
        ),
        boxShadow: [
          if (isCurrentPosition || isSelected)
            BoxShadow(
              color: (isCurrentPosition ? Colors.orange : Colors.green)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            food.emoji,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 5),
          Text(
            food.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('九宫格抽选'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (foods.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('九宫格抽选'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('暂无美食选项，请先添加美食'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('九宫格抽选 (${foods.length}个美食)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '共 ${foods.length} 个美食选项 (${gridColumns}×${gridRows} 网格)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: gridRows * gridColumns,
              itemBuilder: (context, index) {
                return _buildGridItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}


// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import '../models/food_item.dart';
// import '../services/feedback_service.dart';
// import '../services/food_storage_service.dart';

// class GridLotteryPage extends StatefulWidget {
//   const GridLotteryPage({super.key});

//   @override
//   State<GridLotteryPage> createState() => _GridLotteryPageState();
// }

// class _GridLotteryPageState extends State<GridLotteryPage> {
//   List<FoodItem> foods = [];
//   int currentIndex = 0;
//   bool isRunning = false;
//   Timer? timer;
//   int selectedIndex = -1;
//   bool isLoading = true;
//   final ScrollController _scrollController = ScrollController();

//   // 动态计算网格序列（顺时针跑马灯路径）
//   List<int> get gridSequence {
//     final cols = gridColumns;
//     final rows = gridRows;
//     List<int> sequence = [];
    
//     // 外圈顺时针：上边 → 右边 → 下边 → 左边
//     // 上边（从左到右）
//     for (int i = 0; i < cols; i++) {
//       sequence.add(i);
//     }
//     // 右边（从上到下，跳过第一个）
//     for (int i = 1; i < rows; i++) {
//       sequence.add(i * cols + cols - 1);
//     }
//     // 下边（从右到左，跳过第一个）
//     if (rows > 1) {
//       for (int i = cols - 2; i >= 0; i--) {
//         sequence.add((rows - 1) * cols + i);
//       }
//     }
//     // 左边（从下到上，跳过第一个和最后一个）
//     if (cols > 1) {
//       for (int i = rows - 2; i > 0; i--) {
//         sequence.add(i * cols);
//       }
//     }
    
//     return sequence;
//   }

//   // 根据美食数量动态计算网格列数和行数
//   int get gridColumns => 3; // 固定3列
//   int get gridRows {
//     if (foods.isEmpty) return 3;
//     return ((foods.length + gridColumns - 1) / gridColumns).ceil();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadFoods();
//   }

//   Future<void> _loadFoods() async {
//     final allFoods = await FoodStorageService.getAllFoods();
//     setState(() {
//       foods = allFoods;
//       isLoading = false;
//     });
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _startLottery() {
//     if (isRunning || foods.isEmpty) return;

//     FeedbackService.playSpinSound();
//     FeedbackService.mediumVibrate();

//     setState(() {
//       isRunning = true;
//       currentIndex = 0;
//       selectedIndex = Random().nextInt(foods.length);
//     });

//     int rounds = 0;
//     const totalRounds = 3; // 转3圈
//     const speedUpDuration = 50; // 初始速度
//     int currentSpeed = speedUpDuration;
//     final sequenceLength = gridSequence.length;

//     timer = Timer.periodic(Duration(milliseconds: currentSpeed), (timer) {
//       FeedbackService.lightVibrate();
//       setState(() {
//         currentIndex = (currentIndex + 1) % sequenceLength;
//       });

//       // 计算当前圈数
//       if (currentIndex == 0) {
//         rounds++;
//       }

//       // 最后一圈减速
//       if (rounds >= totalRounds - 1) {
//         timer.cancel();
//         _slowDown();
//       }
//     });
//   }

//   void _slowDown() {
//     int currentSpeed = 100;
//     int steps = 0;
//     final sequenceLength = gridSequence.length;
//     final targetSteps = (sequenceLength - currentIndex + selectedIndex) % sequenceLength;

//     timer = Timer.periodic(Duration(milliseconds: currentSpeed), (timer) {
//       if (steps >= targetSteps) {
//         timer.cancel();
//         setState(() => isRunning = false);
//         FeedbackService.playSuccessSound();
//         FeedbackService.successVibrate();
//         _showResultDialog();
//         return;
//       }

//       setState(() {
//         currentIndex = (currentIndex + 1) % sequenceLength;
//       });

//       steps++;
//       currentSpeed += 50; // 逐渐减速
//     });
//   }

//   void _showResultDialog() {
//     final selectedFood = foods[selectedIndex];
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('🎉 恭喜！'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               selectedFood.emoji,
//               style: const TextStyle(fontSize: 64),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               selectedFood.name,
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               selectedFood.description,
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('确定'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGridItem(int index) {
//     final cols = gridColumns;
//     final rows = gridRows;
//     final centerRow = rows ~/ 2;
//     final centerCol = cols ~/ 2;
//     final centerIndex = centerRow * cols + centerCol;
    
//     // 中间位置是开始按钮
//     if (index == centerIndex) {
//       return Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.orange.shade400,
//               Colors.deepOrange.shade600,
//             ],
//           ),
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.orange.withOpacity(0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: isRunning ? null : _startLottery,
//             borderRadius: BorderRadius.circular(15),
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     isRunning ? Icons.stop : Icons.play_arrow,
//                     color: Colors.white,
//                     size: 40,
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     isRunning ? '抽取中...' : '开始',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     // 计算在gridSequence中的位置
//     final sequenceIndex = gridSequence.indexOf(index);
//     if (sequenceIndex == -1 || sequenceIndex >= foods.length) {
//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(15),
//         ),
//       );
//     }

//     final food = foods[sequenceIndex];
//     final isCurrentPosition = isRunning && gridSequence[currentIndex] == index;
//     final isSelected = !isRunning &&
//         selectedIndex >= 0 &&
//         selectedIndex == sequenceIndex;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       decoration: BoxDecoration(
//         color: isCurrentPosition
//             ? Colors.yellow.shade300
//             : isSelected
//                 ? Colors.green.shade300
//                 : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(
//           color: isCurrentPosition
//               ? Colors.orange
//               : isSelected
//                   ? Colors.green
//                   : Colors.grey.shade300,
//           width: isCurrentPosition || isSelected ? 3 : 1,
//         ),
//         boxShadow: [
//           if (isCurrentPosition || isSelected)
//             BoxShadow(
//               color: (isCurrentPosition ? Colors.orange : Colors.green)
//                   .withOpacity(0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             food.emoji,
//             style: const TextStyle(fontSize: 40),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             food.name,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('九宫格抽选'),
//         ),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (foods.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('九宫格抽选'),
//         ),
//         body: const Center(
//           child: Text('暂无美食选项'),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('九宫格抽选'),
//       ),
//       body: SingleChildScrollView(
//         controller: _scrollController,
//         padding: const EdgeInsets.all(20),
//         child: GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             crossAxisSpacing: 10,
//             mainAxisSpacing: 10,
//             childAspectRatio: 1,
//           ),
//           itemCount: gridRows * gridColumns,
//           itemBuilder: (context, index) {
//             return _buildGridItem(index);
//           },
//         ),
//       ),
//     );
//   }
// }
