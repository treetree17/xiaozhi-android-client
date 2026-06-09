import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_assistant/utils/audio_util.dart';

/// VAD 配置管理 Provider
class VadProvider extends ChangeNotifier {
  static const String _prefKeyEnabled = 'vad_enabled';
  static const String _prefKeyThreshold = 'vad_threshold';
  static const String _prefKeyMinSpeechMs = 'vad_min_speech_ms';
  static const String _prefKeySilenceTimeoutMs = 'vad_silence_timeout_ms';
  
  bool _enabled = false;
  double _threshold = 0.02;
  int _minSpeechMs = 300;
  int _silenceTimeoutMs = 1500;
  double _currentLevel = 0.0;
  bool _isSpeaking = false;
  
  VadProvider() {
    _loadSettings();
  }
  
  bool get enabled => _enabled;
  double get threshold => _threshold;
  int get minSpeechMs => _minSpeechMs;
  int get silenceTimeoutMs => _silenceTimeoutMs;
  double get currentLevel => _currentLevel;
  bool get isSpeaking => _isSpeaking;
  
  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKeyEnabled) ?? false;
      _threshold = prefs.getDouble(_prefKeyThreshold) ?? 0.02;
      _minSpeechMs = prefs.getInt(_prefKeyMinSpeechMs) ?? 300;
      _silenceTimeoutMs = prefs.getInt(_prefKeySilenceTimeoutMs) ?? 1500;
      notifyListeners();
    } catch (e) {
      print('VadProvider: 加载设置失败: $e');
    }
  }
  
  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, _enabled);
      await prefs.setDouble(_prefKeyThreshold, _threshold);
      await prefs.setInt(_prefKeyMinSpeechMs, _minSpeechMs);
      await prefs.setInt(_prefKeySilenceTimeoutMs, _silenceTimeoutMs);
    } catch (e) {
      print('VadProvider: 保存设置失败: $e');
    }
  }
  
  /// 切换 VAD 启用状态
  Future<void> toggleEnabled() async {
    _enabled = !_enabled;
    await _saveSettings();
    notifyListeners();
  }
  
  /// 设置 VAD 启用状态
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    await _saveSettings();
    notifyListeners();
  }
  
  /// 设置阈值
  Future<void> setThreshold(double value) async {
    _threshold = value.clamp(0.001, 0.5);
    await _saveSettings();
    notifyListeners();
  }
  
  /// 设置最小语音持续时间
  Future<void> setMinSpeechMs(int value) async {
    _minSpeechMs = value.clamp(100, 2000);
    await _saveSettings();
    notifyListeners();
  }
  
  /// 设置静音超时
  Future<void> setSilenceTimeoutMs(int value) async {
    _silenceTimeoutMs = value.clamp(500, 5000);
    await _saveSettings();
    notifyListeners();
  }
  
  /// 更新当前音量级别（由外部调用）
  void updateLevel(double level) {
    _currentLevel = level;
  }
  
  /// 更新说话状态（由外部调用）
  void updateSpeakingState(bool speaking) {
    if (_isSpeaking != speaking) {
      _isSpeaking = speaking;
      notifyListeners();
    }
  }
}
