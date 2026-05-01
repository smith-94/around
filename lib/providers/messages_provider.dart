import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_mode.dart';
import '../models/message.dart';
import '../services/messages_service.dart';
import '../services/mock_data.dart';

class MessagesProvider extends ChangeNotifier {
  MessagesProvider({MessagesService? service})
      : _service = service ?? MessagesService();

  final MessagesService _service;
  StreamSubscription? _sub;

  String? _me;
  String? _other;
  List<ChatMessage> messages = [];
  bool sending = false;

  Future<void> open({required String me, required String other}) async {
    _me = me;
    _other = other;

    if (AppModeConfig.isPreview) {
      messages = MockData.conversationWith(other);
      notifyListeners();
      return;
    }

    messages = await _service.fetchConversation(me: me, other: other);
    notifyListeners();

    _sub?.cancel();
    _sub = _service.messageStream().listen((rows) {
      final filtered = rows
          .where((r) =>
              (r['sender_id'] == me && r['receiver_id'] == other) ||
              (r['sender_id'] == other && r['receiver_id'] == me))
          .map((r) => ChatMessage.fromJson(r))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      messages = filtered;
      notifyListeners();
    });
  }

  Future<void> send(String content) async {
    if (_me == null || _other == null) return;
    if (content.trim().isEmpty) return;

    if (AppModeConfig.isPreview) {
      messages = [
        ...messages,
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          senderId: _me!,
          receiverId: _other!,
          content: content.trim(),
          createdAt: DateTime.now(),
        ),
      ];
      notifyListeners();
      return;
    }

    sending = true;
    notifyListeners();
    try {
      await _service.send(
        senderId: _me!,
        receiverId: _other!,
        content: content.trim(),
      );
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void close() {
    _sub?.cancel();
    _sub = null;
    messages = [];
    _me = null;
    _other = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
