import 'dart:convert';

class WSCommand {
  static int _reqId = 0;

  /// 生成订阅或取消订阅命令
  static String build({required String cmd, required List<String> topics}) {
    final id = (_reqId++).toString();
    final req = {
      "id": id,
      "cmd": cmd,
      "params": topics,
      "ts": DateTime.now().millisecondsSinceEpoch,
    };
    return json.encode(req);
  }

  /// 快捷方法：订阅
  static String subscribe(List<String> topics) =>
      build(cmd: "SUBSCRIBE", topics: topics);

  /// 快捷方法：取消订阅
  static String unsubscribe(List<String> topics) =>
      build(cmd: "UN_SUBSCRIBE", topics: topics);
}
