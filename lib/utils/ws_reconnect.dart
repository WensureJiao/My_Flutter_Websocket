import 'dart:async';

import 'package:flutter/material.dart';

/// 管理 WebSocket 的断线重连
class ReconnectManager {
  final Future<void> Function() reconnectCallback; // 要重连时执行的方法
  final VoidCallback? onReconnectFail; // 多次重连失败后的回调

  int _retryCount = 0; // 当前重试次数
  Timer? _timer; // 定时器，用来延迟重连
  bool _stopped = false; // 标记是否已停止重连

  ReconnectManager({required this.reconnectCallback, this.onReconnectFail});

  /// 安排一次重连
  void scheduleReconnect() {
    if (_stopped) return;

    _retryCount++;
    final delay = _getDelay(_retryCount);

    print("${_retryCount} 次重连，${delay.inSeconds} 秒后重试...");

    _timer?.cancel(); // 取消之前的定时器
    // 使用定时器延迟执行重连
    _timer = Timer(delay, () async {
      try {
        await reconnectCallback();
      } catch (e) {
        print("重连失败: $e");
        scheduleReconnect(); // 继续安排下一次重连
      }
    });

    // 如果超过最大次数，可以触发回调
    if (_retryCount > 5) {
      onReconnectFail?.call(); // 多次重连失败，执行回调
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

  /// 重试等待时间（指数退避：1, 2, 4, 8, 16 秒）
  Duration _getDelay(int retryCount) {
    final seconds = (1 << (retryCount - 1));
    return Duration(seconds: seconds > 16 ? 16 : seconds);
  }
}
