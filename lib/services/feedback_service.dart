import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'settings_service.dart';

class FeedbackService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 播放点击音效
  static Future<void> playClickSound() async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      // 忽略音频播放错误
    }
  }
  
  // 播放旋转音效
  static Future<void> playSpinSound() async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/spin.mp3'));
    } catch (e) {
      // 忽略音频播放错误
    }
  }
  
  // 播放成功音效
  static Future<void> playSuccessSound() async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // 忽略音频播放错误
    }
  }
  
  // 播放刮擦音效
  static Future<void> playScratchSound() async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/scratch.mp3'));
    } catch (e) {
      // 忽略音频播放错误
    }
  }
  
  // 短震动
  static Future<void> lightVibrate() async {
    if (!await SettingsService.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
  }
  
  // 中等震动
  static Future<void> mediumVibrate() async {
    if (!await SettingsService.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }
  
  // 长震动
  static Future<void> heavyVibrate() async {
    if (!await SettingsService.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }
  
  // 成功震动模式（短-停-短-停-长）
  static Future<void> successVibrate() async {
    if (!await SettingsService.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasCustomVibrationsSupport() ?? false) {
        Vibration.vibrate(
          pattern: [0, 50, 50, 50, 50, 200],
          intensities: [0, 128, 0, 128, 0, 255],
        );
      } else {
        Vibration.vibrate(duration: 300);
      }
    }
  }
  
  // 摇动震动模式
  static Future<void> shakeVibrate() async {
    if (!await SettingsService.isVibrationEnabled()) return;
    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasCustomVibrationsSupport() ?? false) {
        Vibration.vibrate(
          pattern: [0, 100, 50, 100, 50, 100],
          intensities: [0, 200, 0, 200, 0, 200],
        );
      } else {
        Vibration.vibrate(duration: 400);
      }
    }
  }
  
  // 停止所有音效
  static Future<void> stopSound() async {
    await _audioPlayer.stop();
  }
  
  // 取消震动
  static Future<void> cancelVibration() async {
    Vibration.cancel();
  }
  
  // 释放资源
  static void dispose() {
    _audioPlayer.dispose();
  }
}
