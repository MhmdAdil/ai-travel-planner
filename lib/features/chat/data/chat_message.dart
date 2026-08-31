enum ChatRole { user, model }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
  });

  final ChatRole role;
  final String text;

  Map<String, dynamic> toHistoryJson() => {
        'role': role == ChatRole.user ? 'user' : 'model',
        'text': text,
      };
}
