import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('New Chat',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _users.isEmpty
          ? const Center(
          child: Text('No other users found',
              style: TextStyle(color: AppColors.textHint)))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty
                  ? (user.name.isNotEmpty
                      ? Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 24))
                  : null,
            ),
            title: Text(
              user.name.isEmpty ? user.phone : user.name,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            subtitle: user.name.isEmpty
                ? null
                : Text(user.phone,
                style: const TextStyle(color: AppColors.textHint)),
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
    // Replace NewChatScreen with ChatScreen in the stack
    // Stack becomes: Home → Chat (back button returns to Home)
    context.pushReplacement(
      '/home/chat/$chatId',
      extra: {'otherUserId': otherUser.id},
    );
  }
}