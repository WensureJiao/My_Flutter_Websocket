import 'package:flutter/material.dart';
import 'WebSocket/ws_service.dart';

void main() {
  runApp(MaterialApp(home: WebSocketPage()));
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({Key? key}) : super(key: key);

  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  final wsService = WebSocketService("wss://wss.woox.io/v3/public?device=web");
  List<Map<String, dynamic>> messages = [];
  bool connected = false;

  @override
  void initState() {
    super.initState();
    wsService.stream.listen((data) {
      setState(() {
        messages.insert(0, data);
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
      appBar: AppBar(title: Text("WebSocket Demo")),
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
                child: Text("Connect"),
              ),
              ElevatedButton(
                onPressed: connected
                    ? () {
                        wsService.disconnect();
                        setState(() => connected = false);
                      }
                    : null,
                child: Text("Disconnect"),
              ),
              ElevatedButton(
                onPressed: connected
                    ? () {
                        wsService.subscribe(["indexprices"]);
                      }
                    : null,
                child: Text("Subscribe"),
              ),
              ElevatedButton(
                onPressed: connected
                    ? () {
                        wsService.unsubscribe(["indexprices"]);
                      }
                    : null,
                child: Text("Unsubscribe"),
              ),
            ],
          ),
          Divider(), //分割线
          Expanded(
            //消息列表，占满剩余空间
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (_, index) {
                return ListTile(title: Text(messages[index].toString()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
