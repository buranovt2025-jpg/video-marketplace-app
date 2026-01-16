import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!_controller.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    await Future.wait([
      _controller.fetchConversations(),
      _controller.fetchUnreadCount(),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _otherUserId(Map<String, dynamic> c) {
    final candidates = [
      c['other_user_id'],
      c['partner_id'],
      c['user_id'],
      c['peer_id'],
      (c['other_user'] is Map ? (c['other_user'] as Map)['id'] : null),
    ];
    for (final v in candidates) {
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty && s != _controller.userId) return s;
    }
    return '';
  }

  String _otherUserName(Map<String, dynamic> c) {
    final candidates = [
      c['other_user_name'],
      c['partner_name'],
      c['user_name'],
      (c['other_user'] is Map ? (c['other_user'] as Map)['name'] : null),
    ];
    for (final v in candidates) {
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return 'chat'.tr;
  }

  String _lastMessage(Map<String, dynamic> c) {
    final last = c['last_message'];
    if (last is Map) {
      final content = last['content']?.toString().trim();
      if (content != null && content.isNotEmpty) return content;
    }
    final content = c['last_message']?.toString().trim();
    if (content != null && content.isNotEmpty && content is! Map) return content;
    final alt = c['last_message_content']?.toString().trim();
    if (alt != null && alt.isNotEmpty) return alt;
    return 'no_messages_yet'.tr;
  }

  int _unread(Map<String, dynamic> c) {
    final candidates = [c['unread_count'], c['unread']];
    for (final v in candidates) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      final i = int.tryParse(s ?? '');
      if (i != null) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('chat'.tr, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _refresh,
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: !_controller.isLoggedIn
          ? _buildLoginRequired()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: Obx(() {
                    final list = _controller.conversations;
                    if (list.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.forum_outlined, size: 80, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            'no_conversations'.tr,
                            style: TextStyle(color: Colors.grey[400], fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'conversations_will_appear_after_orders'.tr,
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black),
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final id = _otherUserId(c);
                        final name = _otherUserName(c);
                        final last = _lastMessage(c);
                        final unread = _unread(c);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[850],
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(last, style: TextStyle(color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: unread > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : null,
                          onTap: id.isEmpty
                              ? null
                              : () => Get.to(() => ChatScreen(userId: id, userName: name)),
                        );
                      },
                    );
                  }),
                ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'login_required'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'login_to_continue'.tr,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: Text('login'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

