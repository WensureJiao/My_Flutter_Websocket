import 'package:flutter/material.dart';
import 'websocket/ws_service.dart'; // 引入你之前写的 WebSocketService
import 'widgets/message_list.dart';
import 'widgets/websocet_controls.dart';

void main() {
  runApp(MaterialApp(home: WebSocketDemoPage()));
}

class WebSocketDemoPage extends StatefulWidget {
  const WebSocketDemoPage({Key? key}) : super(key: key);

  @override
  State<WebSocketDemoPage> createState() => _WebSocketDemoPageState();
}

class _WebSocketDemoPageState extends State<WebSocketDemoPage> {
  final wsService = WebSocketService("wss://wss.woox.io/v3/public?device=web");
  bool connected = false;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    // 监听 WebSocket 推送
    wsService.stream.listen((data) {
      setState(() {
        messages.insert(0, data); // 最新消息插入到最前
      });
    });
  }

  @override
  void dispose() {
    wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WebSocket Demo")),
      body: Column(
        children: [
          WebSocketControls(
            connected: connected,
            onConnect: () async {
              await wsService.connect();
              setState(() => connected = true);
            },
            onDisconnect: () {
              wsService.disconnect();
              setState(() => connected = false);
            },
            onSubscribe: () => wsService.subscribe(["indexprices"]),
            onUnsubscribe: () => wsService.unsubscribe(["indexprices"]),
          ),
          const Divider(),
          Expanded(child: MessageListView(messages: messages)),
        ],
      ),
    );
  }
}
