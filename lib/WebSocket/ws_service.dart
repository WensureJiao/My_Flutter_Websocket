import 'dart:async';
import 'dart:convert';

import 'package:web_socket/web_socket.dart';

class WebSocketService {
  final String url;
  WebSocket? _socket;
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController.broadcast();
  int _reqId = 0; //每次发送请求（subscribe/unsubscribe）都会自增，用作唯一请求 ID。

  WebSocketService(this.url);

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  Future<void> connect() async {
    _socket = await WebSocket.connect(Uri.parse(url));

    _socket?.events.listen(
      (event) {
        // 文本消息
        if (event is TextDataReceived) {
          final data = json.decode(event.text);

          // 处理 ping
          if (data['ping'] != null) {
            _sendPong(data['ping']);
            return;
          }

          _streamController.add(data);
        }
        // 二进制消息（可选）
        else if (event is BinaryDataReceived) {
          print('收到二进制数据: ${event.data}');
        }
        // 连接关闭事件
        else if (event is CloseReceived) {
          print('WebSocket closed: code=${event.code}, reason=${event.reason}');
        }
      },
      onError: (error) {
        print("WebSocket error: $error");
      },
      onDone: () {
        print("WebSocket closed");
      },
    );
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
  }

  void subscribe(List<String> topics) {
    if (_socket == null) return;
    final id = (_reqId++).toString();
    final req = {
      "id": id,
      "cmd": "SUBSCRIBE",
      "params": topics,
      "ts": DateTime.now().millisecondsSinceEpoch,
    };
    _socket?.sendText(json.encode(req));
  }

  void unsubscribe(List<String> topics) {
    if (_socket == null) return;
    final id = (_reqId++).toString();
    final req = {
      "id": id,
      "cmd": "UN_SUBSCRIBE",
      "params": topics,
      "ts": DateTime.now().millisecondsSinceEpoch,
    };
    _socket?.sendText(json.encode(req));
  }

  void _sendPong(int ping) {
    final pong = {"pong": ping};
    _socket?.sendText(json.encode(pong));
  }

  void dispose() {
    _streamController.close();
    disconnect();
  }
}
