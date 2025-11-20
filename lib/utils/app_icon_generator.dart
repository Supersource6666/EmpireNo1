import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// 应用图标预览生成器
/// 运行此页面可以生成图标预览，然后截图保存
class AppIconGenerator extends StatelessWidget {
  const AppIconGenerator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('应用图标预览'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '截图此图标区域',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              width: 512,
              height: 512,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: const _IconPreview(),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. 截图上方正方形区域\n'
              '2. 保存为 app_icon.png\n'
              '3. 放入 assets/icon/ 目录\n'
              '4. 运行 flutter pub run flutter_launcher_icons',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPreview extends StatelessWidget {
  const _IconPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF9800),
            const Color(0xFFF57C00),
          ],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 碗
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(140),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 米饭
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(120),
                        topRight: Radius.circular(120),
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 饭粒装饰
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RiceGrain(),
                            const SizedBox(width: 15),
                            _RiceGrain(),
                            const SizedBox(width: 15),
                            _RiceGrain(),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RiceGrain(),
                            const SizedBox(width: 15),
                            _RiceGrain(),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RiceGrain(),
                            const SizedBox(width: 15),
                            _RiceGrain(),
                            const SizedBox(width: 15),
                            _RiceGrain(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 筷子
            Positioned(
              right: 60,
              top: 30,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: 12,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 80,
              top: 35,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 12,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiceGrain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
    );
  }
}
