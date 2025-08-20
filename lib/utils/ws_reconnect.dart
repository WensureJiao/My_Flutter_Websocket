import 'dart:async';
import 'package:flutter/material.dart';

typedef VoidAsyncCallback = Future<void> Function();

class ReconnectManager {
  final VoidAsyncCallback reconnectCallback; // 重连时执行
  final VoidCallback? onReconnectFail; // 多次重连失败回调
  final int maxRetry; // 最大重试次数
  final int maxDelaySeconds; // 最大延迟时间（指数退避上限）

  int _retryCount = 0; // 当前重试次数
  Timer? _timer; // 定时器
  bool _stopped = false; // 是否已停止重连

  ReconnectManager({
    required this.reconnectCallback,
    this.onReconnectFail,
    this.maxRetry = 5,
    this.maxDelaySeconds = 16,
  });

  /// 安排重连
  void scheduleReconnect() {
    if (_stopped) return; // 如果已停止重连则不再执行

    _retryCount++; // 增加重试次数
    final delay = _getDelay(_retryCount);
    print("第 $_retryCount 次重连，$delay 秒后尝试...");

    _timer?.cancel(); // 取消之前的定时器
    _timer = Timer(delay, () async {
      try {
        await reconnectCallback();
      } catch (e) {
        print("重连失败: $e");
        // 如果没有超过最大次数，继续重连
        if (_retryCount < maxRetry) {
          scheduleReconnect();
        } else {
          onReconnectFail?.call();
          stop();
        }
      }
    });

    // 超过最大次数立即触发失败回调
    if (_retryCount > maxRetry) {
      onReconnectFail?.call();
      stop();
    }
  }

  /// 成功连接时重置状态
  void reset() {
    _retryCount = 0;
    _timer?.cancel();
    _stopped = false;
  }

  /// 停止重连
  void stop() {
    _timer?.cancel();
    _stopped = true;
  }

  /// 计算指数退避延迟
  Duration _getDelay(int retryCount) {
    final seconds = (1 << (retryCount - 1));
    return Duration(
      seconds: seconds > maxDelaySeconds ? maxDelaySeconds : seconds,
    );
  }
}
