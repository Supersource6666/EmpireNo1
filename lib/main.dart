import 'package:flutter/material.dart';
import 'pages/lucky_wheel_page.dart';
import 'pages/grid_lottery_page.dart';
import 'pages/slot_machine_page.dart';
import 'pages/random_picker_page.dart';
import 'pages/shake_page.dart';
import 'pages/scratch_card_page.dart';
import 'pages/settings_page.dart';
import 'pages/custom_food_page.dart';
import 'pages/chat_room_page.dart';
import 'pages/book_reader_page.dart';
import 'pages/schedule_helper_page.dart';
import 'services/feedback_service.dart';

void main() {
  print('【调试】main() 启动');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '帝国1号',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const FoodSelectorPage(),
    const ChatRoomPage(),
    const BookReaderPage(),
    const ScheduleHelperPage(),
  ];

  @override
  Widget build(BuildContext context) {
    print('【调试】HomePage build 渲染, 当前tab: "+_selectedIndex.toString()+"');
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: '美食选择器',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: '聊天室',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: '听读书',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note),
              label: '日程助手',
            ),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class FoodSelectorPage extends StatelessWidget {
  const FoodSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade300,
            Colors.pink.shade300,
            Colors.purple.shade300,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部按钮栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                    iconSize: 28,
                    tooltip: '自定义美食',
                    onPressed: () {
                      FeedbackService.playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomFoodPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    iconSize: 28,
                    tooltip: '设置',
                    onPressed: () {
                      FeedbackService.playClickSound();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 标题
            const Text(
              '🍽️ 美食选择器',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black26,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '今天不知道吃什么？让我帮你选！',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // 抽奖方式选择
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildLotteryCard(
                    context,
                    title: '大转盘',
                    emoji: '🎡',
                    description: '转盘抽奖\n随机停在美食上',
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LuckyWheelPage(),
                      ),
                    ),
                  ),
                  _buildLotteryCard(
                    context,
                    title: '九宫格',
                    emoji: '🎯',
                    description: '跑马灯抽奖\n体验紧张刺激',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GridLotteryPage(),
                      ),
                    ),
                  ),
                  _buildLotteryCard(
                    context,
                    title: '老虎机',
                    emoji: '🎰',
                    description: '三连滚轮\n看看运气如何',
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SlotMachinePage(),
                      ),
                    ),
                  ),
                  _buildLotteryCard(
                    context,
                    title: '随机选择',
                    emoji: '🎲',
                    description: '快速抽取\n简单直接',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RandomPickerPage(),
                      ),
                    ),
                  ),
                  _buildLotteryCard(
                    context,
                    title: '摇一摇',
                    emoji: '📱',
                    description: '摇动手机\n随机抽取',
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShakePage(),
                      ),
                    ),
                  ),
                  _buildLotteryCard(
                    context,
                    title: '刮刮乐',
                    emoji: '🎫',
                    description: '刮开涂层\n查看美食',
                    color: Colors.amber,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScratchCardPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '选择一种抽奖方式开始吧！',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotteryCard(
    BuildContext context, {
    required String title,
    required String emoji,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        FeedbackService.playClickSound();
        FeedbackService.lightVibrate();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
