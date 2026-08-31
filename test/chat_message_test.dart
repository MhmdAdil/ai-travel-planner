import 'package:ai_travel_planner_frontend/features/chat/data/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat message serializes Gemini-compatible history roles', () {
    const user = ChatMessage(role: ChatRole.user, text: 'Hello');
    const model = ChatMessage(role: ChatRole.model, text: 'Hi');

    expect(user.toHistoryJson(), {'role': 'user', 'text': 'Hello'});
    expect(model.toHistoryJson(), {'role': 'model', 'text': 'Hi'});
  });
}
