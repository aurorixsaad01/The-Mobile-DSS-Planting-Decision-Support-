enum ChatRole { user, botanist }

class ChatMessage {
  final String text;
  final ChatRole role;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
