import 'package:flutter/material.dart';

class MessageListView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;

  const MessageListView({Key? key, required this.messages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const Center(child: Text("暂无数据"));

    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final msg = messages[index];
        if (msg["topic"] == "indexprices") {
          final dataList = msg["data"] as List<dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
    );
  }
}
