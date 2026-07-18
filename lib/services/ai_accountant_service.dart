import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin client for the Anthropic Messages API, used to power the AI
/// Accountant chat. Requires the user's own API key (entered in
/// AI Settings and stored locally on-device — never bundled with the app).
class AiAccountantService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';

  /// Reasonably capable and inexpensive for a numbers-grounded Q&A
  /// assistant. Change this if you'd like to use a different Claude model.
  static const _model = 'claude-sonnet-5';

  static const _systemPrompt =
      'You are an AI accountant for a small GPS-tracking service business '
      'called SJ TRACKING SOLUTION. You are given a snapshot of the '
      "business's current invoices, receipts, and GPS service statuses as "
      'plain text context. Answer the user\'s question using ONLY the '
      'numbers and facts in that context — never invent figures. If the '
      'context does not contain enough information to answer, say so '
      'plainly. Be concise, use the currency shown in the context, and '
      'format money and dates clearly. When useful, suggest a concrete '
      'next action (e.g. "follow up with X, whose invoice is 12 days '
      'overdue").';

  /// Sends [question] along with [contextSummary] (the business's current
  /// financial snapshot) and returns the assistant's reply as plain text.
  /// Throws an [AiAccountantException] with a user-friendly message on
  /// failure.
  static Future<String> ask({
    required String apiKey,
    required String question,
    required String contextSummary,
    List<Map<String, String>> priorTurns = const [],
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AiAccountantException(
          'No API key configured. Add your Anthropic API key in AI Settings first.');
    }

    final messages = [
      ...priorTurns.map((turn) => {'role': turn['role'], 'content': turn['content']}),
      {
        'role': 'user',
        'content': 'BUSINESS DATA SNAPSHOT:\n$contextSummary\n\nQUESTION: $question',
      },
    ];

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey.trim(),
              'anthropic-version': _apiVersion,
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 1024,
              'system': _systemPrompt,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw AiAccountantException('Could not reach the AI service. Check your internet connection.');
    }

    if (response.statusCode == 401) {
      throw AiAccountantException('Invalid API key. Double-check it in AI Settings.');
    }
    if (response.statusCode == 429) {
      throw AiAccountantException('Rate limit reached. Please wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        detail = decoded['error']?['message'] ?? response.body;
      } catch (_) {}
      throw AiAccountantException('AI request failed (${response.statusCode}): $detail');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['content'] as List<dynamic>? ?? [];
      final text = content
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String)
          .join('\n');
      if (text.trim().isEmpty) {
        throw AiAccountantException('The AI returned an empty response. Try again.');
      }
      return text.trim();
    } catch (e) {
      if (e is AiAccountantException) rethrow;
      throw AiAccountantException('Could not parse the AI response.');
    }
  }
}

class AiAccountantException implements Exception {
  final String message;
  AiAccountantException(this.message);

  @override
  String toString() => message;
}
