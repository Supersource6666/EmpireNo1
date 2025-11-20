import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  
  static SharedPreferences? _prefs;

  // 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 获取音效开关状态
  static Future<bool> isSoundEnabled() async {
    if (_prefs == null) await init();
    return _prefs!.getBool(_soundEnabledKey) ?? true;
  }

  // 设置音效开关
  static Future<bool> setSoundEnabled(bool enabled) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_soundEnabledKey, enabled);
  }

  // 获取震动开关状态
  static Future<bool> isVibrationEnabled() async {
    if (_prefs == null) await init();
    return _prefs!.getBool(_vibrationEnabledKey) ?? true;
  }

  // 设置震动开关
  static Future<bool> setVibrationEnabled(bool enabled) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_vibrationEnabledKey, enabled);
  }
}
