import 'dart:async';

import '../models/message.dart';
import 'supabase_service.dart';

class MessagesService {
  Future<List<ChatMessage>> fetchConversation({
    required String me,
    required String other,
  }) async {
    final rows = await SupabaseService.client
        .from('messages')
        .select()
        .or('and(sender_id.eq.$me,receiver_id.eq.$other),and(sender_id.eq.$other,receiver_id.eq.$me)')
        .order('created_at');
    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> send({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    await SupabaseService.client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  Stream<List<Map<String, dynamic>>> messageStream() {
    return SupabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at');
  }
}
