import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/auth_service.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../domain/entities/chat_message.dart';
import '../cubits/chat_cubit.dart';
import '../cubits/chat_state.dart';

/// Slide-up chat panel for the Watch Together room.
class ChatPanel extends StatefulWidget {
  final String roomId;
  final VoidCallback onClose;

  const ChatPanel({super.key, required this.roomId, required this.onClose});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(children: [
                const Icon(Icons.chat_bubble, color: Color(0xFFE50914), size: 20),
                const SizedBox(width: 10),
                const Text('Chat', style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
                ),
              ]),
            ),

            // Messages
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (ctx, state) {
                  if (state is ChatLoaded) {
                    _scrollToBottom();
                    return state.messages.isEmpty
                      ? Center(child: Text('No messages yet',
                          style: TextStyle(color: Colors.white.withOpacity(0.3))))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: state.messages.length,
                          itemBuilder: (_, i) => _buildMessage(state.messages[i]),
                        );
                  }
                  return const Center(child: CircularProgressIndicator(
                    color: Color(0xFFE50914), strokeWidth: 2));
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(context),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE50914),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _send(BuildContext ctx) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    ctx.read<ChatCubit>().sendMessage(text);
    _msgController.clear();
  }

  Widget _buildMessage(ChatMessage msg) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(msg.text,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12,
              fontStyle: FontStyle.italic)),
        )),
      );
    }

    final isMe = msg.senderUid == AuthService.currentUid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe
            ? const Color(0xFFE50914).withOpacity(0.85)
            : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(msg.senderName,
                  style: TextStyle(color: Colors.amber[300], fontSize: 11,
                    fontWeight: FontWeight.bold)),
              ),
            Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
