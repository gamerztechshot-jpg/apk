// features/mantra_generator/services/mantra_ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:karmasu/core/config/supabase_config.dart';
import '../models/chat_message_model.dart';

class MantraAIService {
  static const String _edgeFunctionUrl =
      '${SupabaseConfig.supabaseUrl}/functions/v1/generate-mantra';

  /// Generate mantra using Supabase Edge Function
  Future<String> generateMantra({
    required String text,
    String? problemId,
    String? userId,
    String? sessionId,
    List<ChatMessage>? chatHistory,
    String? language, // "hi" or "en"
  }) async {
    try {

      // Validate input
      if (text.isEmpty) {
        throw Exception('Text cannot be empty');
      }

      if (text.length > 300) {
        throw Exception('Text must be 300 characters or less');
      }

      // Build chat history for API
      List<Map<String, dynamic>>? apiChatHistory;
      if (chatHistory != null && chatHistory.isNotEmpty) {
        apiChatHistory = chatHistory.map((msg) {
          return {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text,
          };
        }).toList();
      }

      // Prepare request body
      final requestBody = {
        'text': text,
        if (problemId != null) 'problemId': problemId,
        if (userId != null) 'userId': userId,
        if (sessionId != null) 'sessionId': sessionId,
        if (apiChatHistory != null) 'chatHistory': apiChatHistory,
        if (language != null) 'language': language, // Pass language parameter
      };
      


      // Get Supabase session for authorization
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final authToken = session?.accessToken ?? SupabaseConfig.supabaseAnonKey;


      // Make HTTP request to Edge Function
      final response = await http
          .post(
            Uri.parse(_edgeFunctionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'apikey': SupabaseConfig.supabaseAnonKey,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );


      // Handle response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Try both 'mantra' and 'reply' fields
        final mantra = responseData['mantra'] as String? ?? 
                     responseData['reply'] as String?;

        if (mantra == null || mantra.isEmpty) {
          throw Exception('No mantra generated');
        }

        return mantra.trim();
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error']?.toString() ??
            'Failed to generate mantra (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to generate mantra: $e');
    }
  }

  /// Build chat context from chat history
  List<Map<String, dynamic>> buildChatContext(List<ChatMessage> chatHistory) {
    return chatHistory.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      };
    }).toList();
  }
}
