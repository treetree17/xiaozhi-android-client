import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vad/vad.dart';
import 'package:ai_assistant/utils/audio_util.dart';

/// VAD 自动唤醒管理器
/// 使用 Silero VAD 模型检测语音活动，实现"说话就自动开始对话"
class VadAutoWake {
  static const String TAG = "VadAutoWake";
  
  VadHandler? _vadHandler;
  bool _isEnabled = false;
  bool _isListening = false;
  
  // 回调
  Function()? onSpeechStart;
  Function()? onSpeechEnd;
  Function(List<double> audioSamples)? onSpeechEndWithAudio;
  Function(String error)? onError;
  
  /// 是否启用
  bool get isEnabled => _isEnabled;
  
  /// 是否正在监听
  bool get isListening => _isListening;
  
  /// 初始化并启动 VAD 监听
  Future<void> start() async {
    if (_isListening) {
      print('$TAG: 已经在监听中');
      return;
    }
    
    try {
      print('$TAG: 初始化 VAD...');
      
      // 创建 VadHandler
      _vadHandler = VadHandler.create(isDebug: false);
      
      // 设置回调 - 和 digital-human 一样的逻辑
      _vadHandler!.onSpeechStart.listen((_) {
        print('$TAG: 检测到语音开始');
        onSpeechStart?.call();
      });
      
      _vadHandler!.onSpeechEnd.listen((List<double> samples) {
        print('$TAG: 检测到语音结束，样本数: ${samples.length}');
        onSpeechEnd?.call();
        onSpeechEndWithAudio?.call(samples);
      });
      
      _vadHandler!.onError.listen((String message) {
        print('$TAG: VAD 错误: $message');
        onError?.call(message);
      });
      
      // 开始监听
      await _vadHandler!.startListening(
        positiveSpeechThreshold: 0.5,
        negativeSpeechThreshold: 0.35,
        minSpeechFrames: 3,
        model: 'v5',  // 使用 Silero VAD v5 模型
      );
      
      _isEnabled = true;
      _isListening = true;
      print('$TAG: VAD 监听已启动');
    } catch (e) {
      print('$TAG: 启动 VAD 失败: $e');
      onError?.call('启动 VAD 失败: $e');
      rethrow;
    }
  }
  
  /// 停止 VAD 监听
  Future<void> stop() async {
    if (!_isListening || _vadHandler == null) {
      return;
    }
    
    try {
      await _vadHandler!.stopListening();
      _isListening = false;
      print('$TAG: VAD 监听已停止');
    } catch (e) {
      print('$TAG: 停止 VAD 失败: $e');
    }
  }
  
  /// 暂停 VAD 监听（不停止音频流）
  Future<void> pause() async {
    if (!_isListening || _vadHandler == null) {
      return;
    }
    
    try {
      await _vadHandler!.pauseListening();
      print('$TAG: VAD 监听已暂停');
    } catch (e) {
      print('$TAG: 暂停 VAD 失败: $e');
    }
  }
  
  /// 释放资源
  Future<void> dispose() async {
    await stop();
    _vadHandler?.dispose();
    _vadHandler = null;
    _isEnabled = false;
    print('$TAG: VAD 资源已释放');
  }
}
