import 'package:flutter/material.dart';

class WebSocketControls extends StatelessWidget {
  final bool connected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;

  const WebSocketControls({
    Key? key,
    required this.connected,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSubscribe,
    required this.onUnsubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        ElevatedButton(
          onPressed: connected ? null : onConnect,
          child: const Text("Connect"),
        ),
        ElevatedButton(
          onPressed: connected ? onDisconnect : null,
          child: const Text("Disconnect"),
        ),
        ElevatedButton(
          onPressed: connected ? onSubscribe : null,
          child: const Text("Subscribe"),
        ),
        ElevatedButton(
          onPressed: connected ? onUnsubscribe : null,
          child: const Text("Unsubscribe"),
        ),
      ],
    );
  }
}
