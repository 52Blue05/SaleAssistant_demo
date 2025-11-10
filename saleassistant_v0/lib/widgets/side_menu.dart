import 'package:flutter/material.dart';
import 'package:saleassistant_v0/screens/login_screen.dart';
import '../api_service/flutter_api_service.dart';

class SideMenu extends StatefulWidget {
  final SalesAssistantService chatService;
  final VoidCallback onNewChat;
  const SideMenu({
    super.key,
    required this.chatService,
    required this.onNewChat,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  List<ConversationSession> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await widget.chatService.listConversations(limit: 50);
      setState(() => _sessions = sessions);
    } catch (e) {
      debugPrint('❌ Lỗi tải danh sách hội thoại: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Sale Assistant',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Tên user'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('Đoạn chat mới'),
              onTap: () {
                Navigator.pop(context);
                widget.onNewChat(); // Gọi hàm từ ChatScreen
              },
            ),
            /*
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {},
            ),
            */
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Phiên bản: 1.0.0'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '💬 Các đoạn hội thoại',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                  ? const Center(child: Text('Chưa có hội thoại'))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final s = _sessions[index];
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text('Hội thoại #${index + 1}'),
                            subtitle: Text(s.updatedAt.substring(0, 19)),
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                final history = await widget.chatService
                                    .getConversation(s.sessionId);
                                Navigator.pop(context, history);
                              } catch (e) {
                                debugPrint('❌ Lỗi tải hội thoại: $e');
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
