import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _cyan = Color(0xFF06B6D4);
const Color _bgDark = Color(0xFF020F14);
const Color _bgCard = Color(0xFF062330);
const Color _bgSurface = Color(0xFF083040);
const Color _textLight = Color(0xFFE0F7FC);
const Color _textMuted = Color(0xFF7BAABF);

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String otherUserName;
  final String otherUserImage;
  final bool isWorker;

  // ── Optional metadata (stored but not required for UI) ────────
  final String? chatId;
  final String? workerName;
  final String? workerId;
  final String? workerPhone;
  final String? serviceName;
  final String? requestId;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.otherUserName,
    required this.otherUserImage,
    this.isWorker = false,
    this.chatId,
    this.workerName,
    this.workerId,
    this.workerPhone,
    this.serviceName,
    this.requestId,
    this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': widget.currentUserId,
        'senderType': widget.isWorker ? 'worker' : 'user',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update last message on the chat room doc
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': widget.currentUserId,
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message. Try again.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(14),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _bgSurface,
              backgroundImage: widget.otherUserImage.isNotEmpty
                  ? NetworkImage(widget.otherUserImage)
                  : null,
              child: widget.otherUserImage.isEmpty
                  ? Icon(
                      widget.isWorker ? Icons.engineering : Icons.person,
                      color: _cyan,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: _textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show service name in subtitle if provided
                  Text(
                    widget.serviceName?.isNotEmpty == true
                        ? widget.serviceName!
                        : 'Online',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: _textLight, size: 22),
            onPressed: () {
              // Future: launch phone call using workerPhone
              if (widget.workerPhone != null &&
                  widget.workerPhone!.isNotEmpty) {
                debugPrint('Calling: ${widget.workerPhone}');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _cyan),
                  );
                }

                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load messages',
                          style:
                              const TextStyle(color: _textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final msgs = snap.data?.docs ?? [];

                if (msgs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: _textMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: _textMuted, fontSize: 14),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Start the conversation below',
                          style: TextStyle(color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final data = msgs[i].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;
                    final text = data['text'] as String? ?? '';
                    final ts = data['timestamp'] as Timestamp?;
                    final time = ts != null
                        ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                        : '';

                    return _buildMessageBubble(text, time, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _cyan : _bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFF0E3A50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : _textLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.65) : _textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: _bgCard,
        border: Border(top: BorderSide(color: Color(0xFF0E3A50))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: _textLight, fontSize: 14),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                  filled: true,
                  fillColor: _bgSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _cyan, width: 1.2),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isSending ? _cyan.withOpacity(0.5) : _cyan,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
