// features/mantra_generator/views/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/services/auth_service.dart';
import '../../models/main_problem_model.dart';
import '../../models/sub_problem_model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../services/chat_session_service.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final MainProblem mainProblem;
  final SubProblem? subProblem;
  final String? initialMessage;
  final String? sessionId; // For loading existing sessions

  const ChatScreen({
    super.key,
    required this.mainProblem,
    this.subProblem,
    this.initialMessage,
    this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Helper class for navigation with session
class ChatScreenWithSession extends ChatScreen {
  const ChatScreenWithSession({
    super.key,
    required super.mainProblem,
    super.subProblem,
    required String sessionId,
  }) : super(sessionId: sessionId);
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatSessionService _sessionService = ChatSessionService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveChatSession() async {
    try {
      final viewModel = Provider.of<ChatViewModel>(
        context,
        listen: false,
      );
      await viewModel.saveChatSession();
    } catch (e) {
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.getCurrentUser()?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isHindi ? 'चैट' : 'Chat'),
          backgroundColor: Colors.orange.shade600,
        ),
        body: const Center(child: Text('Please login to access chat')),
      );
    }

    final problem = (widget.subProblem ?? widget.mainProblem) as dynamic;

    return WillPopScope(
      onWillPop: () async {
        await _saveChatSession();
        // Wait a bit to ensure save completes
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pop();
        return false; // Prevent default pop, we handle it manually
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        drawer: _buildDrawer(context, userId, isHindi),
        appBar: AppBar(
        title: Text(
          isHindi ? 'AI सखा चैट' : 'AI Sakha Chat',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveChatSession();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Drawer Menu Button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider(
        create: (_) {
          final viewModel = ChatViewModel();
          // Save session when provider is disposed (screen closes)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // This ensures session is saved when screen closes
          });
          // Get language from LanguageService
          final languageCode = isHindi ? "hi" : "en";
          viewModel.initializeChat(
            userId: userId,
            problem: problem,
            sessionId: widget.sessionId,
            language: languageCode, // Pass language to viewmodel
          );
          if (widget.initialMessage != null) {
            viewModel.handleInitialMessage(widget.initialMessage);
          }
          return viewModel;
        },
        child: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            // Update language in ChatViewModel when LanguageService changes
            final viewModel = Provider.of<ChatViewModel>(context, listen: false);
            final currentLanguageCode = languageService.isHindi ? "hi" : "en";
            viewModel.updateLanguage(currentLanguageCode);
            
            return Consumer<ChatViewModel>(
              builder: (context, viewModel, child) {
                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return Column(
              children: [
                // Messages List
                Expanded(
                  child: viewModel.messages.isEmpty
                      ? _buildEmptyState(isHindi)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: viewModel.messages.length,
                          itemBuilder: (context, index) {
                            return ChatMessageBubble(
                              message: viewModel.messages[index],
                            );
                          },
                        ),
                ),
                // Error Banner
                if (viewModel.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.red.shade700,
                          onPressed: () {
                            // Clear error (you may want to add a method in ViewModel)
                          },
                        ),
                      ],
                    ),
                  ),
                // Input Area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Text Input
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: isHindi ? 'अपना प्रश्न लिखें...' : 'Type your question...',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                // Update UI when text changes to enable/disable send button
                                setState(() {});
                              },
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty && !viewModel.isLoading) {
                                  _sendMessage(viewModel);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Send Button
                          Container(
                            decoration: BoxDecoration(
                              color: viewModel.isLoading ||
                                      _messageController.text.trim().isEmpty
                                  ? Colors.grey.shade300
                                  : Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: viewModel.isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                              onPressed: viewModel.isLoading ||
                                      _messageController.text.trim().isEmpty
                                  ? null
                                  : () {
                                      _sendMessage(viewModel);
                                      // Clear loading state after a delay to ensure button re-enables
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () {
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        },
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
                           },
            );
          },
        ),
      ),
    ),
  );
}
  Widget _buildEmptyState(bool isHindi) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    final userName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        (isHindi ? 'उपयोगकर्ता' : 'User');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            isHindi ? 'नमस्ते $userName' : 'Hello $userName',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi ? 'मैं आपकी कैसे मदद कर सकता हूं?' : 'How can I help you today?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi ? 'मैं सखा हूं, मैं सब जानता हूं' : 'I am Sakha, I know everything',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, size: 48, color: Colors.orange.shade600),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'अपना प्रश्न पूछें' : 'Ask your question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi ? 'मैं आपकी समस्या के लिए व्यक्तिगत मंत्र सुझाऊंगा' : 'I will suggest personalized mantras for your problem',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatViewModel viewModel) {
    final text = _messageController.text.trim();
    if (text.isEmpty || viewModel.isLoading) return;

    _messageController.clear();
    // Clear the text field immediately to re-enable send button
    setState(() {});
    
    viewModel.sendMessage(text).then((_) {
      _scrollToBottom();
      // Ensure UI updates after message is sent
      if (mounted) {
        setState(() {});
      }
    }).catchError((error) {
      // Handle error and ensure button is re-enabled
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildDrawer(BuildContext context, String userId, bool isHindi) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<List<ChatSession>>(
          key: ValueKey(DateTime.now().millisecondsSinceEpoch ~/ 1000), // Refresh every second when drawer opens
          future: () async {
            final sessions = await _sessionService.getChatSessions(userId);
            for (var session in sessions) {
            }
            return sessions;
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
            }
            if (snapshot.hasError) {
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data ?? [];

            return Column(
              children: [
                // Enhanced Drawer Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade700,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi ? 'AI सखा चैट' : 'AI Sakha Chat',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHindi
                                      ? 'आपकी चैट इतिहास'
                                      : 'Your Chat History',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sessions List
                Expanded(
                  child: sessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isHindi ? 'कोई चैट इतिहास नहीं' : 'No chat history',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isHindi ? 'अपनी पहली चैट शुरू करें' : 'Start your first chat',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade100,
                                        Colors.orange.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.orange.shade600,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  session.problemTitle ?? session.firstMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.message_outlined,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${session.messages.length} ${isHindi ? 'संदेश' : 'messages'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(
                                          session.updatedAt ?? session.createdAt,
                                          isHindi,
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            onTap: () async {
                              Navigator.of(context).pop(); // Close drawer
                              // Save current session before switching
                              _saveChatSession();
                              
                              // Navigate to chat with this session
                              if (mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreenWithSession(
                                      mainProblem: widget.mainProblem,
                                      subProblem: widget.subProblem,
                                      sessionId: session.sessionId,
                                    ),
                                  ),
                                );
                              }
                            },
                              ),
                            );
                          },
                        ),
                ),
                // New Chat Button - Always creates a NEW session
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close drawer
                      // Save current session before starting new chat
                      _saveChatSession();
                      // Start completely new chat session
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            mainProblem: widget.mainProblem,
                            subProblem: widget.subProblem,
                          ),
                        ),
                      );
                    },
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: Text(
                          isHindi ? 'नई चैट' : 'New Chat',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool isHindi) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return isHindi ? 'अभी' : 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}${isHindi ? 'मि' : 'm'}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}${isHindi ? 'घं' : 'h'}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${isHindi ? 'दिन' : 'd'}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
