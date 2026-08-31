import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../cost_prediction/application/cost_prediction_controller.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';
import '../data/chat_travel_context.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _suggestions = <String>[
    'What can I do in Kandy?',
    'How can I travel from Colombo to Ella?',
    'Suggest budget activities in Galle.',
    'What should I pack for Nuwara Eliya?',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = const [
    ChatMessage(
      role: ChatRole.model,
      text:
          'Hi! I’m your Sri Lanka AI Travel Assistant. Ask me about places, '
          'activities, transport, accommodation, budgets or trip planning.',
    ),
  ].toList();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedText]) async {
    if (_sending) return;

    final text = (suggestedText ?? _controller.text).trim();
    if (text.isEmpty) return;

    final history = List<ChatMessage>.from(_messages);
    if (suggestedText == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, text: text));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final itineraryState = ref.read(itineraryControllerProvider);
      final costState = ref.read(costPredictionControllerProvider);
      final travelContext = ChatTravelContextBuilder.build(
        preference: itineraryState.lastPreference,
        itinerary: itineraryState.itinerary,
        prediction: costState.prediction,
      );

      final reply = await ref.read(chatRepositoryProvider).send(
            message: text,
            history: history,
            travelContext: travelContext,
          );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: ChatRole.model, text: reply));
      });
    } on ChatException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('The travel assistant could not respond. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearChat() {
    setState(() {
      _messages
        ..clear()
        ..add(
          const ChatMessage(
            role: ChatRole.model,
            text:
                'Chat cleared. What would you like to know about travelling in Sri Lanka?',
          ),
        );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chatTitle),
            Text(
              'AI Travel Assistant',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _sending ? null : _clearChat,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (_messages.length <= 1)
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: _sending ? null : () => _send(suggestion),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            _Composer(
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? colors.onPrimary : colors.onSurface,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function([String?]) onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Ask about your Sri Lanka trip...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) {
                  if (!sending) onSend();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: sending ? null : () => onSend(),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
