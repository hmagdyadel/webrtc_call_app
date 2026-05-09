import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/data/models/user_model.dart';
import '../../viewmodel/message_cubit.dart';
import '../../viewmodel/message_state.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final MessageCubit _messageCubit;

  String _otherUserName = '';
  String _otherUserAvatar = '';
  String _otherUserAbout = '';
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;
  
  Timer? _toggleTimer;
  bool _showAbout = true;

  @override
  void initState() {
    super.initState();
    _messageCubit = getIt<MessageCubit>();
    _messageCubit.loadMessages(widget.chatId);
    _loadOtherUser();
    
    _toggleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _showAbout = !_showAbout;
        });
      }
    });
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _messageCubit.close();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();
    if (doc.exists && mounted) {
      final user = UserModel.fromJson({...doc.data()!, 'id': doc.id});
      setState(() {
        _otherUserName = user.name.isNotEmpty ? user.name : 'User';
        _otherUserAvatar = user.avatarUrl;
        _otherUserAbout = user.about;
        _isOtherUserOnline = user.isOnline;
        _otherUserLastSeen = user.lastSeen;
      });
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _messageCubit.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      text: text,
    );
    _controller.clear();
    // Scroll to bottom after short delay for Firestore update
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            backgroundImage:
                _otherUserAvatar.isNotEmpty ? NetworkImage(_otherUserAvatar) : null,
            child: _otherUserAvatar.isEmpty
                ? (_otherUserName.isNotEmpty && !RegExp(r'^[0-9+]+$').hasMatch(_otherUserName)
                    ? Text(
                        _otherUserName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 20))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _otherUserName.isNotEmpty ? _otherUserName : 'Loading...',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildSubtitle(),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Voice call button (placeholder for Phase 9)
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppColors.accent),
          onPressed: () {},
        ),
        // Video call button (placeholder for Phase 10)
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppColors.accent),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    if (_showAbout && _otherUserAbout.isNotEmpty) {
      return Text(
        _otherUserAbout,
        key: const ValueKey('about'),
        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12),
        overflow: TextOverflow.ellipsis,
      );
    }

    if (_isOtherUserOnline) {
      return Text(
        'Online',
        key: const ValueKey('online'),
        style: TextStyle(color: AppColors.online.withValues(alpha: 0.9), fontSize: 12),
        overflow: TextOverflow.ellipsis,
      );
    }

    if (_otherUserLastSeen != null) {
      return Text(
        'Last seen ${_formatLastSeen(_otherUserLastSeen!)}',
        key: const ValueKey('last_seen'),
        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12),
        overflow: TextOverflow.ellipsis,
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    if (dateToCheck == today) {
      return 'today at ${DateFormat('jm').format(lastSeen)}';
    } else if (dateToCheck == yesterday) {
      return 'yesterday at ${DateFormat('jm').format(lastSeen)}';
    } else {
      return DateFormat('MMM d, yyyy').format(lastSeen);
    }
  }

  Widget _buildMessageList() {
    return BlocBuilder<MessageCubit, MessageState>(
      bloc: _messageCubit,
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          loaded: (messages) {
            if (messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text(
                      'Start the conversation 💬',
                      style: TextStyle(color: AppColors.textHint, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ابدأ المحادثة',
                      style: TextStyle(color: AppColors.textHint, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            // Auto-scroll to bottom when new messages arrive
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              }
            });

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageBubble(
                  message: msg,
                  isSent: msg.senderId == widget.currentUserId,
                );
              },
            );
          },
          error: (msg) => Center(
            child: Text(msg, style: const TextStyle(color: AppColors.missed)),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bgInput,
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: AppColors.textHint.withValues(alpha: 0.6),
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.divider, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }
}
