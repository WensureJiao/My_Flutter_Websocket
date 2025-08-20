import 'dart:convert';
import 'package:web_socket/web_socket.dart';

typedef MessageCallback = void Function(Map<String, dynamic> data);
typedef CloseCallback = void Function(int code, String reason);
typedef ErrorCallback = void Function(Object error);

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
  }) {
    socket.events.listen(
      (event) {
        if (event is TextDataReceived) {
          final data = json.decode(event.text);

          // 处理 ping
          if (data['ping'] != null) {
            socket.sendText(json.encode({"pong": data['ping']}));
            return;
          }

          onMessage(data);
        } else if (event is BinaryDataReceived) {
          print('收到二进制数据: ${event.data}');
        } else if (event is CloseReceived) {
          // 使用常量代替硬编码
          final code = event.code ?? WSConst.defaultCloseCode;
          final reason = event.reason;

          print('WebSocket closed: code=$code, reason=$reason');

          if (onClose != null) {
            onClose(code, reason);
          }
        }
      },
      onError: (error) {
        print("WebSocket error: $error");
        if (onError != null) {
          onError(error);
        }
      },
      onDone: () {
        print("WebSocket 已关闭（done 回调）");
        // done 回调也可以触发 onClose，如果需要
      },
    );
  }
}
