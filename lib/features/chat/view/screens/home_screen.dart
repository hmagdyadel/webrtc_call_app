import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../data/models/chat_model.dart';
import '../../viewmodel/chat_cubit.dart';
import '../../viewmodel/chat_state.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0; // Chats tab default
  late final ChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    _chatCubit = getIt<ChatCubit>()..loadChats(widget.userId);
  }

  @override
  void dispose() {
    _chatCubit.close();
    super.dispose();
  }

  late final List<Widget> _screens = [
    _ChatsTab(userId: widget.userId),
    const _CallsTab(),
    const _ExploreTab(),
    const _ContactsTab(),
    const _MeTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: _screens[_currentIndex],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.navBackground,
            selectedItemColor: AppColors.navSelected,
            unselectedItemColor: AppColors.navUnselected,

            selectedFontSize: 11,
            unselectedFontSize: 11,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.phone_outlined),
                activeIcon: Icon(Icons.phone),
                label: 'Calls',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.contacts_outlined),
                activeIcon: Icon(Icons.contacts),
                label: 'Contacts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Me',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  final String userId;
  const _ChatsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text('Chats',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              context.push(AppRoutePaths.qrScanner);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await context.push(AppRoutePaths.newChat);
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            loaded: (chats) => chats.isEmpty
                ? const Center(
                child: Text('No chats yet',
                    style: TextStyle(color: AppColors.textHint)))
                : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherId = chat.members
                    .firstWhere((m) => m != userId);
                return _ChatTile(
                    chat: chat,
                    currentUserId: userId,
                    otherId: otherId);
              },
            ),
            error: (msg) =>
                Center(child: Text(msg, style: const TextStyle(color: AppColors.missed))),
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final String otherId;

  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.otherId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherId).snapshots(),
      builder: (context, snapshot) {
        String displayName = '...';
        String avatarUrl = '';
        
        if (snapshot.hasData && snapshot.data!.exists) {
          try {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final user = UserModel.fromJson({...data, 'id': snapshot.data!.id});
            displayName = user.name.isNotEmpty ? user.name : 'User';
            avatarUrl = user.avatarUrl;
          } catch (e) {
            displayName = 'User';
          }
        } else if (snapshot.hasError || (!snapshot.hasData && snapshot.connectionState == ConnectionState.done)) {
            displayName = 'User';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? (displayName.isNotEmpty && displayName != '...' && !RegExp(r'^[0-9+]+$').hasMatch(displayName)
                    ? Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 24))
                : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageTime != null)
            Text(
              _formatTime(chat.lastMessageTime!),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          if (chat.unreadCount > 0 && chat.lastMessageSenderId != currentUserId)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () => context.push(
        '/home/chat/${chat.id}',
        extra: {'otherUserId': otherId},
      ),
    );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

// ── Calls Tab ──
class _CallsTab extends StatelessWidget {
  const _CallsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text(
          'Calls',
          style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text('No calls yet', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// ── Explore Tab ──
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Text('Explore', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// ── Contacts Tab ──
class _ContactsTab extends StatelessWidget {
  const _ContactsTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Text('Contacts', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// ── Me Tab ──
class _MeTab extends StatelessWidget {
  const _MeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String displayName = 'My Profile';
        String? avatarUrl;

        state.whenOrNull(
          authenticated: (user) {
            displayName = user.name.isNotEmpty ? user.name : 'User';
            avatarUrl = user.avatarUrl.isNotEmpty ? user.avatarUrl : null;
          },
        );

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            elevation: 0,
            title: const Text('Me',
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(displayName,
                    style: const TextStyle(color: Colors.white)),
                subtitle: const Text('Tap to edit profile', style: TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push(AppRoutePaths.profile),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.white),
            title: const Text('My QR Code',
                style: TextStyle(color: Colors.white)),
            onTap: () => context.push(AppRoutePaths.myQr),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthCubit>().signOut();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
      },
    );
  }
}