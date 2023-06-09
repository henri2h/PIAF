import 'dart:convert';

import 'package:matrix/matrix.dart';

import 'famedlysdk_store.dart';

extension ClientInformation on Client {
  Future<List<String>> lastContacted() async {
    final data = await Store().getItem(_getLastOpenedName());
    return data != null ? (jsonDecode(data) as List).cast<String>() : [];
  }

  void increaseLastOpened(String roomId) async {
    List<String> items = await lastContacted();
    items.insert(0, roomId);
    items = items.toSet().toList().take(20).toList();
    await Store().setItem(_getLastOpenedName(), jsonEncode(items));
  }

  String _getLastOpenedName() => "last_opened.$clientName";

  Future<Map<String, String>> getDrafts() async {
    final data = await Store().getItem(_getDraftMessage());
    return data != null ? (jsonDecode(data) as Map).cast<String, String>() : {};
  }

  Future<String?> getDraft(String id) async {
    final map = await getDrafts();
    return map[id];
  }

  void setDraft({required String roomId, required String message}) async {
    Map<String, String> messages = await getDrafts();

    if (message.isNotEmpty) {
      messages[roomId] = message;
    } else {
      messages.remove(roomId);
    }

    await Store().setItem(_getDraftMessage(), jsonEncode(messages));
  }

  String _getDraftMessage() => "draft_message.$clientName";
}
