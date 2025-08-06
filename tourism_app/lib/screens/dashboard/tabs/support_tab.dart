import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/models/chat_message.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/services/smart_chat_service.dart';
import 'package:tourism_app/services/database_adapter.dart';
import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/utils/app_colors.dart';


class SupportTab extends StatefulWidget {
  const SupportTab({Key? key}) : super(key: key);

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final DatabaseAdapter _dbHelper = DatabaseAdapter.instance;
  late AnimationController _animationController;
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadMessages();
    
    // Auto-scroll when new messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
      // Auto-scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _addWelcomeMessage() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?['id'];
    final userName = authProvider.currentUser?['username'] ?? 
                    (languageProvider.currentLanguage == 'en' ? 'Friend' : 'Saaxiib');

    final welcomeMessage = languageProvider.currentLanguage == 'en'
        ? '🌟 Welcome $userName to your Smart Somalia Tourism Assistant! 🇸🇴\n\n'
          'I\'m your intelligent travel companion with access to:\n'
          '🏖️ All ${await _getPlacesCount()} places in our database\n'
          '💰 Real-time pricing and cost comparisons\n'
          '❤️ Your personal favorites and preferences\n'
          '📅 Smart booking recommendations\n'
          '🗣️ Multilingual support (English & Somali)\n'
          '🧠 Context-aware responses\n\n'
          'I can help you find the cheapest places, plan your itinerary, and answer any tourism questions. Just ask me naturally!'
        : '🌟 Ku soo dhawoow $userName kaaliyahaaga caqliga leh ee dalxiiska Soomaaliya! 🇸🇴\n\n'
          'Waxaan ahay saaxiibkaaga safarka ee caqliga leh oo leh:\n'
          '🏖️ Dhammaan ${await _getPlacesCount()} meelaha xogteenna\n'
          '💰 Qiimaha iyo isbarbardhigga kharashka\n'
          '❤️ Meelaha aad jeceshahay iyo dookhyada\n'
          '📅 Talooyinka caqliga leh ee dalbashada\n'
          '🗣️ Taageerada luqadaha (Ingiriisi & Soomaali)\n'
          '🧠 Jawaabaha miyirka leh\n\n'
          'Waxaan kaa caawin karaa inaad hesho meelaha ugu jaban, qorsheynta safarka, iyo jawaabinta su\'aalaha dalxiiska. Kaliya si dabiici ah i weydiiso!';

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
    // Auto-scroll to bottom after adding welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();
    _textFieldFocusNode.unfocus();

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
      final response = await SmartChatService.sendSmartMessage(
          message, languageProvider.currentLanguage, authProvider);

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
      
      // Auto-scroll to bottom after receiving assistant response
      _scrollToBottom();
    } catch (e) {
      print('Chat error: $e');
      
      // Enhanced error handling with more specific messages
      String errorText;
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final userName = authProvider.currentUser?['username'] ?? 
                      (languageProvider.currentLanguage == 'en' ? 'Friend' : 'Saaxiib');
      
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        errorText = languageProvider.currentLanguage == 'en'
            ? '📱 $userName, no internet connection detected. I\'m now running in offline mode with smart assistance!\n\n'
              'I can still help you with places, costs, recommendations, and planning using my built-in knowledge. Ask me anything!'
            : '📱 $userName, internetka lama heli karo. Hadda waxaan ku shaqeynayaa hab offline ah oo caqli leh!\n\n'
              'Weli waan kaa caawin karaa meelaha, qiimaha, talooyinka, iyo qorshaynta iyada oo aan isticmaalayo aqoontayda. Wax walba i weydiiso!';
      } else {
        errorText = languageProvider.currentLanguage == 'en'
            ? '🤖 $userName, smart AI backend is temporarily unavailable, but I\'m still here to help with intelligent offline assistance!\n\n'
              'I have access to all your data and can provide personalized recommendations, cost analysis, and trip planning. Try asking me about the cheapest places or your favorites!'
            : '🤖 $userName, adeegga AI-ga caqliga leh hadda lama heli karo, laakiin weli halkan baan u joogaa si aan kaaga caawiyo!\n\n'
              'Waxaan u leeyahay gelitaan dhammaan xogtaada waxaanan bixin karaa talooyinka gaarka ah, falanqaynta qiimaha, iyo qorshaynta safarka. Isku day inaad i weydiiso meelaha ugu jaban ama kuwa aad jeceshahay!';
      }

      // Save error message
      final errorChatMessage = ChatMessage(
        message: errorText,
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
      
      // Auto-scroll to bottom after error message
      _scrollToBottom();
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          languageProvider.currentLanguage == 'en'
              ? 'Clear Chat'
              : 'Tirtir Wadahadalka',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          languageProvider.currentLanguage == 'en'
              ? 'Are you sure you want to clear all messages?'
              : 'Ma hubtaa inaad doonayso inaad tirtirto dhammaan fariimaha?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              languageProvider.currentLanguage == 'en' ? 'Cancel' : 'Jooji',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              languageProvider.currentLanguage == 'en' ? 'Clear' : 'Tirtir',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];
      await _dbHelper.clearChatMessages(userId);
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.getText('support'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  languageProvider.currentLanguage == 'en'
                      ? 'Tourism Assistant'
                      : 'Caawimaadka Dalxiiska',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.grey,
              ),
            ),
            tooltip: languageProvider.currentLanguage == 'en'
                ? 'Clear Chat'
                : 'Tirtir Wadahadalka',
            onPressed: _clearChat,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(languageProvider)
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, index);
                    },
                  ),
          ),
          _buildTypingIndicator(),
          _buildInputArea(languageProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider languageProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              languageProvider.currentLanguage == 'en'
                  ? 'Somalia Tourism Assistant'
                  : 'Kaaliyaha Dalxiiska Soomaaliya',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              languageProvider.currentLanguage == 'en'
                  ? 'Ask me about:\n• Beach costs and locations\n• Historical sites and fees\n• Accommodation prices\n• Transportation costs\n• Food and dining expenses'
                  : 'Wax ka weydiiso:\n• Qiimaha xeebaha iyo meelaha\n• Meelaha taariikhiga ah iyo lacagta\n• Qiimaha hoyga\n• Kharashka gaadiidka\n• Cuntada iyo kharashka cuntada',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                languageProvider.currentLanguage == 'en'
                    ? '💡 Try: "How much does Lido Beach cost?"'
                    : '💡 Isku day: "Lido Beach immisa ayay ku kacaysaa?"',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  Provider.of<LanguageProvider>(context).currentLanguage == 'en'
                      ? 'Typing...'
                      : 'Waa qoraya...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isLastMessage = index == _messages.length - 1;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: EdgeInsets.only(
        bottom: isLastMessage ? 16 : 8,
        top: index == 0 ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.9)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _textFieldFocusNode,
                  decoration: InputDecoration(
                    hintText: languageProvider.currentLanguage == 'en'
                        ? 'Type your message...'
                        : 'Qor fariintaaga...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _sendMessage,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return Provider.of<LanguageProvider>(context, listen: false)
                  .currentLanguage ==
              'en'
          ? 'Just now'
          : 'Hadda';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Future<int> _getPlacesCount() async {
    try {
      // Use PlacesService to get accurate count from backend API
      final places = await PlacesService.getAllPlaces();
      return places.length;
    } catch (e) {
      print('❌ Error getting places count from backend: $e');
      // Fallback to local database
      try {
        return await _dbHelper.getPlacesCount();
      } catch (fallbackError) {
        print('❌ Error getting places count from local database: $fallbackError');
        return 50; // Default fallback number
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }
}
