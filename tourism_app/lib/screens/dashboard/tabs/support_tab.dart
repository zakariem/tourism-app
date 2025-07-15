import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/models/chat_message.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/services/chat_service.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/language_toggle.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({Key? key}) : super(key: key);

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?['id'];

    final messages = await _dbHelper.getChatMessages(userId);
    if (messages.isEmpty) {
      _addWelcomeMessage();
    } else {
      setState(() {
        _messages.addAll(messages.map((m) => ChatMessage.fromMap(m)));
      });
    }
  }

  void _addWelcomeMessage() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?['id'];

    final welcomeMessage = languageProvider.currentLanguage == 'en'
        ? 'Hello! I\'m your tourism assistant. How can I help you explore Somalia today?'
        : 'Salaam! Waxaan ahay caawimaadkaaga dalxiiska. Sideen kuu caawin karaa baahitaanka Soomaaliya maanta?';

    final message = ChatMessage(
      message: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
      userId: userId,
    );

    final id = await _dbHelper.insertChatMessage(message.toMap());
    setState(() {
      _messages.add(message.copyWith(id: id));
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?['id'];

    // Save user message
    final userMessage = ChatMessage(
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
      userId: userId,
    );
    final userMessageId =
        await _dbHelper.insertChatMessage(userMessage.toMap());

    setState(() {
      _messages.add(userMessage.copyWith(id: userMessageId));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final response = await ChatService.sendMessage(
          message, languageProvider.currentLanguage);

      // Save assistant message
      final assistantMessage = ChatMessage(
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
        userId: userId,
      );
      final assistantMessageId =
          await _dbHelper.insertChatMessage(assistantMessage.toMap());

      setState(() {
        _messages.add(assistantMessage.copyWith(id: assistantMessageId));
        _isLoading = false;
      });
    } catch (e) {
      final errorMessage = Provider.of<LanguageProvider>(context, listen: false)
                  .currentLanguage ==
              'en'
          ? 'Sorry, I encountered an error. Please try again.'
          : 'Waan ka xumahay, waxaa dhacay khalad. Fadlan isku day mar kale.';

      // Save error message
      final errorChatMessage = ChatMessage(
        message: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
        userId: userId,
      );
      final errorMessageId =
          await _dbHelper.insertChatMessage(errorChatMessage.toMap());

      setState(() {
        _messages.add(errorChatMessage.copyWith(id: errorMessageId));
        _isLoading = false;
      });
    }

    _scrollToBottom();
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
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('support')),
        automaticallyImplyLeading: false,
        actions: const [
          LanguageToggle(
            showLabel: true,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: languageProvider.currentLanguage == 'en'
                            ? 'Type your message...'
                            : 'Qor fariintaaga...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
