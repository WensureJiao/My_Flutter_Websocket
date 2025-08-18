import 'package:flutter/material.dart';
import 'WebSocket/ws_service.dart'; // 引入你之前写的 WebSocketService

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
          Wrap(
            spacing: 10,
            children: [
              ElevatedButton(
                onPressed: connected
                    ? null
                    : () async {
                        await wsService.connect();
                        setState(() => connected = true);
                      },
                child: const Text("Connect"),
              ),
              ElevatedButton(
                onPressed: connected
                    ? () {
                        wsService.disconnect();
                        setState(() => connected = false);
                      }
                    : null,
                child: const Text("Disconnect"),
              ),
              ElevatedButton(
                onPressed: connected
                    ? () {
                        wsService.subscribe(["indexprices"]);
                      }
                    : null,
                child: const Text("Subscribe"),
              ),
              ElevatedButton(
                onPressed: connected
                    ? () {
                        wsService.unsubscribe(["indexprices"]);
                      }
                    : null,
                child: const Text("Unsubscribe"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text("暂无数据"))
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final msg = messages[index];
                      if (msg["topic"] == "indexprices") {
                        // 格式化 indexprices 数据
                        final dataList = msg["data"] as List<dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: dataList.map((item) {
                                return Text(
                                  "${item['s']} -> ${item['px']} (ts:${item['ts']})",
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      } else {
                        return ListTile(title: Text(msg.toString()));
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
