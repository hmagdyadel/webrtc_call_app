import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../data/sources/chat_remote_source.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authState = context.read<AuthCubit>().state;
    String? currentUserId;

    authState.whenOrNull(
      authenticated: (user) => currentUserId = user.id,
    );

    if (currentUserId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .get();

    if (!mounted) return;
    setState(() {
      _users = snapshot.docs
          .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('New Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(
          child: Text('No other users found',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2196F3),
              child: Text(
                user.phone.substring(user.phone.length - 2),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14),
              ),
            ),
            title: Text(
              user.name.isEmpty ? user.phone : user.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: user.name.isEmpty
                ? null
                : Text(user.phone,
                style: const TextStyle(color: Colors.grey)),
            onTap: () => _startChat(context, user),
          );
        },
      ),
    );
  }

  Future<void> _startChat(BuildContext context, UserModel otherUser) async {
    final authState = context.read<AuthCubit>().state;
    String? currentUserId;
    authState.whenOrNull(authenticated: (user) => currentUserId = user.id);
    if (currentUserId == null) return;

    final chatSource = getIt<ChatRemoteSource>();
    final chatId =
    await chatSource.createOrGetChat(currentUserId!, otherUser.id);

    if (!context.mounted) return;
    context.pop(chatId);
  }
}