import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';

import '../models/chat_message.dart';
import '../models/diagnostic_result.dart';

// the chat screen where users talk to Alifs the botanist

class BotanistChatScreen extends StatefulWidget {
  final DiagnosticResult? contextualPlant;

  const BotanistChatScreen({super.key, this.contextualPlant});

  @override
  State<BotanistChatScreen> createState() => _BotanistChatScreenState();
}

class _BotanistChatScreenState extends State<BotanistChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  final List<OpenAIChatCompletionChoiceMessageModel> _apiHistory = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeGroq();
    _initializeChat();
  }

  void _initializeGroq() {
    // ⚠️ ADD YOUR OWN GROQ API CREDENTIALS BELOW
    // Get your API key from: https://console.groq.com/keys
    OpenAI.baseUrl = 'YOUR_GROQ_BASE_URL';  // e.g. 'https://api.groq.com/openai'
    OpenAI.apiKey = 'YOUR_GROQ_API_KEY';     // e.g. 'gsk_...'
  }

  void _initializeChat() {
    // set up the AI's personality and role before the conversation starts
    _apiHistory.add(
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            'You are Alifs, an elite, highly empathetic botanical expert '
            'and professional gardener. Your goal is to help users save their plants '
            'with clear, highly actionable, step-by-step advice. Be warm, encouraging, '
            'and always end with a practical next step.',
          ),
        ],
        role: OpenAIChatMessageRole.system,
      ),
    );

    // if the user opened the chat from a scan result, mention that specific plant in the greeting
    String greeting;
    if (widget.contextualPlant != null) {
      final plant = widget.contextualPlant!;
      greeting =
          'Hello! I see we\'re discussing your ${plant.plantName} (${plant.scientificName}). '
          'How can I help you care for it today? 🌿';
    } else {
      greeting =
          'Hello! I\'m Alifs, your personal botanist companion. '
          'Tell me about your plant — what\'s worrying you today?';
    }

    _apiHistory.add(OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(greeting),
      ],
      role: OpenAIChatMessageRole.assistant,
    ));

    _messages.add(ChatMessage(text: greeting, role: ChatRole.botanist));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, role: ChatRole.user));
      _apiHistory.add(OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(text),
        ],
        role: OpenAIChatMessageRole.user,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await OpenAI.instance.chat.create(
        model: 'llama-3.3-70b-versatile',
        messages: _apiHistory,
      );

      final replyText = response.choices.first.message.content?.first.text;
      if (replyText != null && mounted) {
        setState(() {
          _messages.add(ChatMessage(text: replyText, role: ChatRole.botanist));
          _apiHistory.add(OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(replyText),
            ],
            role: OpenAIChatMessageRole.assistant,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Groq API error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alifs',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Expert Botanist',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  _TypingDots(),
                ],
              ),
            ),

          // Input bar
          _ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            isTyping: _isTyping,
          ),
            ],
          ),
        ),
      ),
    );
  }
}

// the individual chat bubble widget — user messages go right, Alifs messages go left
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF1B2124),
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// the animated dots that show while Alifs is typing a reply
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final double phase = ((_controller.value * 3) - i).clamp(0.0, 1.0);
              final double opacity = phase < 0.5
                  ? phase * 2
                  : (1 - phase) * 2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                      46, 125, 50, opacity.clamp(0.2, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// the text field and send button at the bottom of the chat
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isTyping;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask Alifs anything about your plants…',
                  hintStyle: TextStyle(
                      color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF7FAF7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isTyping ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isTyping
                      ? Colors.grey[300]
                      : const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: isTyping ? Colors.grey[500] : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
