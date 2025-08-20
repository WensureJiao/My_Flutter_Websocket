import 'dart:async';
import 'dart:convert';
import 'package:web_socket/web_socket.dart';

typedef MessageCallback = void Function(Map<String, dynamic> data);
typedef CloseCallback = void Function(int code, String reason);
typedef ErrorCallback = void Function(Object error);
typedef PingTimeoutCallback = void Function();

/// WebSocket 默认值常量
class WSConst {
  static const int defaultCloseCode = 0; // 未知关闭码
  static const String defaultCloseReason = 'unknown'; // 未知关闭原因
}

/// WebSocket 标准关闭码（可选）
class WSCloseCode {
  static const int normal = 1000;
  static const int goingAway = 1001;
  static const int abnormal = 1006;
}

class WSEventHandler {
  /// 统一处理 WebSocket 事件
  static void listenEvents({
    required WebSocket socket,
    required MessageCallback onMessage,
    CloseCallback? onClose,
    ErrorCallback? onError,
    PingTimeoutCallback? onPingTimeout, // 可选 ping 超时回调
    Duration pingTimeout = const Duration(seconds: 10), // 默认 ping 超时  时间
  }) {
    Timer? pingTimer; // 定时器用于处理 ping 超时

    void resetPingTimer() {
      // 重置 ping 定时器
      pingTimer?.cancel();
      pingTimer = Timer(pingTimeout, () {
        print("未收到 ping，触发 pingTimeout");
        onPingTimeout?.call(); // 触发 ping 超时回调
      });
    }

    // 初始化 ping 定时器
    resetPingTimer();

    socket.events.listen(
      (event) {
        if (event is TextDataReceived) {
          final data = json.decode(event.text);

          // 处理 ping
          if (data['ping'] != null) {
            socket.sendText(json.encode({"pong": data['ping']}));
            resetPingTimer(); // 收到 ping 重置定时器
            return;
          }

          onMessage(data);
        } else if (event is BinaryDataReceived) {
          print('收到二进制数据: ${event.data}');
        } else if (event is CloseReceived) {
          final code = event.code ?? WSConst.defaultCloseCode;
          final reason = event.reason;
          print('WebSocket closed: code=$code, reason=$reason');
          onClose?.call(code, reason);
        }
      },
      onError: (error) {
        print("WebSocket error: $error");
        onError?.call(error);
      },
      onDone: () {
        print("WebSocket done 回调触发");
        // done 回调也可能表示连接关闭
        onClose?.call(WSConst.defaultCloseCode, WSConst.defaultCloseReason);
      },
    );
  }
}
