class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.isUser,
    required this.text,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
