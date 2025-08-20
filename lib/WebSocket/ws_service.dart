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

  final List<String> _pendingTopics = []; // 保存订阅主题

  Timer? _pingTimer;
  final Duration pingTimeout = const Duration(seconds: 10);

  late final ReconnectManager _reconnectManager;

  WebSocketService(this.url) {
    _reconnectManager = ReconnectManager(
      reconnectCallback: _connectInternal,
      onReconnectFail: () {
        print("多次重连失败，放弃重连");
      },
    );
  }

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  /// 手动连接
  Future<void> connect() async => await _connectInternal();

  /// 内部连接逻辑
  Future<void> _connectInternal() async {
    try {
      _socket = await WebSocket.connect(Uri.parse(url));
      print("WebSocket 已连接: $url");

      _reconnectManager.reset();
      _pingTimer?.cancel();

      WSEventHandler.listenEvents(
        socket: _socket!,
        onMessage: (data) => _streamController.add(data),
        onClose: (code, reason) => _reconnectManager.scheduleReconnect(),
        onError: (_) => _reconnectManager.scheduleReconnect(),
        onPingTimeout: () => _reconnectManager.scheduleReconnect(), // 直接触发重连
        pingTimeout: const Duration(seconds: 15),
      );

      // 重连成功后恢复订阅
      if (_pendingTopics.isNotEmpty) subscribe(_pendingTopics);
    } catch (e) {
      print("连接失败: $e");
      _reconnectManager.scheduleReconnect();
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _socket?.close();
    _socket = null;
    _reconnectManager.stop();
  }

  void subscribe(List<String> topics) {
    if (_socket == null) return;
    _pendingTopics.addAll(topics.where((t) => !_pendingTopics.contains(t)));
    _socket?.sendText(WSCommand.subscribe(topics));
  }

  void unsubscribe(List<String> topics) {
    if (_socket == null) return;
    _pendingTopics.removeWhere((t) => topics.contains(t));
    _socket?.sendText(WSCommand.unsubscribe(topics));
  }

  void dispose() {
    _streamController.close();
    disconnect();
  }
}
