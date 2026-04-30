import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
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

  int _currentIndex = 1; // Chats tab default

  late final List<Widget> _screens = [
    const _CallsTab(),
    _ChatsTab(userId: widget.userId),
    const _ExploreTab(),
    const _ContactsTab(),
    const _MeTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _screens[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF222222),
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: const Color(0xFF888888),

          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_outlined),
              activeIcon: Icon(Icons.phone),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
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
    );
  }
}

class _ChatsTab extends StatelessWidget {
  final String userId;
  const _ChatsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatCubit>()..loadChats(userId),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: const Text('Chats',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {}),
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
                child: Text('Loading chats...', style: TextStyle(color: Colors.grey)),
              ),
              loaded: (chats) => chats.isEmpty
                  ? const Center(
                  child: Text('No chats yet',
                      style: TextStyle(color: Colors.grey)))
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
                  Center(child: Text(msg, style: const TextStyle(color: Colors.red))),
            );
          },
        ),
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF2196F3),
        child: Text(
          otherId.substring(0, 2).toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      title: Text(
        otherId,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: chat.lastMessageTime != null
          ? Text(
        _formatTime(chat.lastMessageTime!),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      )
          : null,
      onTap: () {},
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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
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
      backgroundColor: Color(0xFF1A1A1A),
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
      backgroundColor: Color(0xFF1A1A1A),
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Me',
            style: TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2196F3),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text('My Profile',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
            onTap: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
    );
  }
}