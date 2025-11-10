import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SalesAssistantService {
  static const String baseUrl =
      'https://sales-assistant-api-846714563215.asia-southeast1.run.app';

  final String userId;
  String? sessionId;

  SalesAssistantService(this.userId);

  // Gửi tin nhắn tới AI (POST /chat)
  Future<ChatResponse> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        'user_id': userId,
      }),
    );

    debugPrint('📤 POST $baseUrl/chat');
    debugPrint(
      '📨 Request body: ${jsonEncode({'message': message, 'session_id': sessionId, 'user_id': userId})}',
    );
    debugPrint('📥 Status code: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      sessionId = data['session_id']; // Cập nhật session ID
      return ChatResponse.fromJson(data);
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please wait and try again.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to send message');
    }
  }

  // Liệt kê các hội thoại (GET /conversations)
  Future<List<ConversationSession>> listConversations({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations?user_id=$userId&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['sessions'] as List)
          .map((session) => ConversationSession.fromJson(session))
          .toList();
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  // Lấy toàn bộ nội dung hội thoại (GET /conversations/{session_id})
  Future<ConversationHistory> getConversation(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$sessionId?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      return ConversationHistory.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Conversation not found');
    } else {
      throw Exception('Failed to load conversation');
    }
  }

  // Xóa hội thoại (DELETE /conversations/{session_id})
  Future<void> deleteConversation(String sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/conversations/$sessionId?user_id=$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete conversation');
    }
  }
}

// =======================
// Data model definitions
// =======================

class ChatResponse {
  final String response;
  final String sessionId;
  final String? userId;

  ChatResponse({required this.response, required this.sessionId, this.userId});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'],
      sessionId: json['session_id'],
      userId: json['user_id'],
    );
  }
}

class ConversationSession {
  final String sessionId;
  final String? userId;
  final String createdAt;
  final String updatedAt;
  final int messageCount;

  ConversationSession({
    required this.sessionId,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      sessionId: json['session_id'],
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      messageCount: json['message_count'],
    );
  }
}

class ConversationHistory {
  final String sessionId;
  final String? userId;
  final List<ChatMessage> messages;
  final String createdAt;
  final String updatedAt;

  ConversationHistory({
    required this.sessionId,
    this.userId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationHistory.fromJson(Map<String, dynamic> json) {
    return ConversationHistory(
      sessionId: json['session_id'],
      userId: json['user_id'],
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg))
          .toList(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(role: json['role'], content: json['content']);
  }
}
