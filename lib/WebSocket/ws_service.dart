import 'dart:async';
import 'package:my_websocket/utils/ws_command.dart';
import 'package:web_socket/web_socket.dart';
import 'package:my_websocket/utils/ws_event_handler.dart';
import 'package:my_websocket/utils/ws_reconnect.dart';

class WebSocketService {
  final String url;
  WebSocket? _socket;
  final StreamController<Map<String, dynamic>> _streamController =
      StreamController.broadcast();

  late final ReconnectManager _reconnectManager; // 断线重连管理器

  WebSocketService(this.url) {
    // 初始化断线重连管理器
    _reconnectManager = ReconnectManager(
      reconnectCallback: _connectInternal, // 自动重连时调用
      onReconnectFail: () {
        print("多次重连失败，放弃重连");
      },
    );
  }

  /// 对外暴露 stream，用于 UI 层监听
  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  /// 手动连接 WebSocket
  Future<void> connect() async {
    await _connectInternal();
  }

  /// 内部连接逻辑，ReconnectManager 会调用
  Future<void> _connectInternal() async {
    try {
      _socket = await WebSocket.connect(Uri.parse(url));
      print("WebSocket 已连接: $url");

      // 连接成功后重置重连状态
      _reconnectManager.reset();

      // 开始监听事件（复用 WSEventHandler）
      WSEventHandler.listenEvents(
        socket: _socket!,
        onMessage: (data) {
          _streamController.add(data); // 收到消息直接推给 UI
        },
        onClose: (code, reason) {
          print("连接关闭 code=$code, reason=$reason");
          _reconnectManager.scheduleReconnect(); // 触发重连
        },
        onError: (error) {
          print("WebSocket 错误: $error");
          _reconnectManager.scheduleReconnect(); // 触发重连
        },
      );
    } catch (e) {
      print("连接失败: $e");
      _reconnectManager.scheduleReconnect(); // 连接失败也触发重连
    }
  }

  /// 主动断开连接
  void disconnect() {
    _socket?.close();
    _socket = null;
    _reconnectManager.stop(); // 停止自动重连
  }

  /// 订阅主题（复用 WSCommand）
  void subscribe(List<String> topics) {
    if (_socket == null) return;
    _socket?.sendText(WSCommand.subscribe(topics));
  }

  /// 退订主题（复用 WSCommand）
  void unsubscribe(List<String> topics) {
    if (_socket == null) return;
    _socket?.sendText(WSCommand.unsubscribe(topics));
  }

  /// 资源释放
  void dispose() {
    _streamController.close();
    disconnect();
  }
}
