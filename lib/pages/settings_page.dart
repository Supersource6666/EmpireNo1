import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/feedback_service.dart';
import '../utils/app_icon_generator.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sound = await SettingsService.isSoundEnabled();
    final vibration = await SettingsService.isVibrationEnabled();
    setState(() {
      _soundEnabled = sound;
      _vibrationEnabled = vibration;
      _isLoading = false;
    });
  }

  Future<void> _toggleSound(bool value) async {
    await SettingsService.setSoundEnabled(value);
    setState(() {
      _soundEnabled = value;
    });
    if (value) {
      FeedbackService.playClickSound();
    }
  }

  Future<void> _toggleVibration(bool value) async {
    await SettingsService.setVibrationEnabled(value);
    setState(() {
      _vibrationEnabled = value;
    });
    if (value) {
      FeedbackService.lightVibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),
                _buildSectionTitle('反馈设置'),
                _buildSettingTile(
                  icon: Icons.volume_up,
                  title: '音效',
                  subtitle: _soundEnabled ? '已开启' : '已关闭',
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                ),
                _buildSettingTile(
                  icon: Icons.vibration,
                  title: '震动',
                  subtitle: _vibrationEnabled ? '已开启' : '已关闭',
                  value: _vibrationEnabled,
                  onChanged: _toggleVibration,
                ),
                const Divider(height: 40),
                _buildSectionTitle('关于'),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  title: '版本',
                  value: '1.0.0',
                ),
                _buildInfoTile(
                  icon: Icons.restaurant_menu,
                  title: '美食种类',
                  value: '中餐、西餐、日韩料理等',
                ),
                const Divider(height: 40),
                _buildSectionTitle('开发工具'),
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.orange),
                  title: const Text('生成应用图标'),
                  subtitle: const Text('查看图标预览并截图保存'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppIconGenerator(),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        activeColor: Colors.orange,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
