import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/side_menu.dart';
import '../api_service/flutter_api_service.dart'; // 👈 Import file API service

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> messages = [
    {"text": "Xin chào! Tôi có thể giúp gì cho bạn?", "isUser": false},
  ];

  late SalesAssistantService _chatService;
  List<ConversationSession> _sessions = [];
  bool _isLoadingSessions = false;

  @override
  void initState() {
    super.initState();
    _chatService = SalesAssistantService('user123'); // 👈 Gán userId tạm thời

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startNewChat() {
    debugPrint('🆕 Bắt đầu đoạn chat mới');
    setState(() {
      messages.clear();
      messages.add({
        "text": "Xin chào! Tôi có thể giúp gì cho bạn?",
        "isUser": false,
      });
      _chatService.sessionId = null; // Reset session
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    debugPrint('🟢 Gửi message: $text');

    setState(() {
      messages.add({"text": text, "isUser": true});
      messages.add({"text": "Đang xử lý yêu cầu của bạn...", "isUser": false});
    });

    try {
      final response = await _chatService.sendMessage(text);
      debugPrint('✅ Phản hồi từ API: ${response.response}');
      debugPrint('📦 Session ID: ${response.sessionId}');
      debugPrint('👤 User ID: ${response.userId}');

      setState(() {
        messages.removeLast(); // Xóa dòng "Đang xử lý..."
        messages.add({"text": response.response, "isUser": false});
      });
    } catch (e, stack) {
      debugPrint('❌ Lỗi khi gọi API: $e');
      debugPrint('🪜 Stacktrace: $stack');

      setState(() {
        messages.removeLast();
        messages.add({"text": "❌ Lỗi: ${e.toString()}", "isUser": false});
      });
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await _chatService.listConversations(limit: 50);
      setState(() {
        _sessions = sessions;
      });
      debugPrint('📋 Tải ${sessions.length} hội thoại thành công');
    } catch (e) {
      debugPrint('❌ Lỗi khi tải danh sách hội thoại: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách hội thoại')),
      );
    } finally {
      setState(() => _isLoadingSessions = false);
    }
  }

  late AnimationController _animController;
  bool _isRecording = false;

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideMenu(chatService: _chatService, onNewChat: _startNewChat),

      appBar: AppBar(
        title: const Text("Sale Assistant"),
        /*
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            onPressed: () {},
            tooltip: "Bảng báo giá",
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
            tooltip: "SaleKit",
          ),

          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text("Chia sẻ đoạn chat"),
              ),
              const PopupMenuItem(value: 'save', child: Text("Lưu trữ")),
              const PopupMenuItem(value: 'report', child: Text("Báo cáo")),
            ],
            onSelected: (value) {},
          ),
        ],
        */
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageBubble(text: msg["text"], isUser: msg["isUser"]);
              },
            ),
          ),
          const SizedBox(height: 10),
          InputBar(onSend: _sendMessage),
        ],
      ),
      // Nút thu âm dạng hoạt hình
      /*floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            double pulse =
                1 + 0.1 * math.sin(_animController.value * 2 * math.pi);
            double borderPulse =
                3 + 3 * (math.sin(_animController.value * 2 * math.pi).abs());

            return Transform.scale(
              scale: pulse,
              child: GestureDetector(
                onLongPressStart: (_) => setState(() => _isRecording = true),
                onLongPressEnd: (_) => setState(() => _isRecording = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [Colors.red, Colors.deepOrange]
                          : [Colors.redAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.6),
                        blurRadius: _isRecording ? 20 : 10,
                        spreadRadius: _isRecording ? 4 : 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.8),
                      width: borderPulse,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic_none_rounded : Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            );
          },
        ),
      ),*/
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildConversationList() {
    if (_isLoadingSessions) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("Chưa có hội thoại nào.")),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "🗂 Danh sách hội thoại",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = _sessions[index];
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text("Hội thoại #${index + 1}"),
                    subtitle: Text(
                      "Cập nhật: ${s.updatedAt.substring(0, 19)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text("${s.messageCount} tin nhắn"),
                    onTap: () async {
                      Navigator.pop(context); // đóng danh sách
                      debugPrint('📖 Mở hội thoại: ${s.sessionId}');
                      try {
                        final history = await _chatService.getConversation(
                          s.sessionId,
                        );
                        setState(() {
                          messages.clear();
                          for (var m in history.messages) {
                            messages.add({
                              "text": m.content,
                              "isUser": m.role == "user",
                            });
                          }
                        });
                      } catch (e) {
                        debugPrint('❌ Lỗi khi tải hội thoại: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể tải hội thoại'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
