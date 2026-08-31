import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import 'chat_message.dart';

class ChatRepository {
  ChatRepository(this._apiService);

  final ApiService _apiService;

  Future<String> send({
    required String message,
    required List<ChatMessage> history,
    String travelContext = '',
  }) async {
    try {
      final response = await _apiService.sendChatMessage({
        'message': message,
        'history': history.map((item) => item.toHistoryJson()).toList(),
        'travelContext': travelContext,
      });

      final data = response.data;
      if (data is Map && data['reply'] is String) {
        final reply = (data['reply'] as String).trim();
        if (reply.isNotEmpty) {
          return reply;
        }
      }

      throw const ChatException('The AI assistant returned an empty response.');
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        throw ChatException(data['message'] as String);
      }

      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          throw const ChatException(
            'Could not reach the travel assistant. Check that the backend is running.',
          );
        case DioExceptionType.receiveTimeout:
          throw const ChatException(
            'The AI assistant is taking too long to respond. Please try again.',
          );
        default:
          throw const ChatException(
            'Something went wrong while contacting the travel assistant.',
          );
      }
    }
  }
}

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiServiceProvider));
});
