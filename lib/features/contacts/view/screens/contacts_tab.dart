import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../../chat/data/sources/chat_remote_source.dart';
import '../../viewmodel/contacts_cubit.dart';
import '../../viewmodel/contacts_state.dart';

class ContactsTab extends StatefulWidget {
  final String userId;
  const ContactsTab({super.key, required this.userId});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    context.read<ContactsCubit>().loadContacts(widget.userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startChat(BuildContext context, UserModel otherUser) async {
    final authState = context.read<AuthCubit>().state;
    String? currentUserId;
    authState.whenOrNull(authenticated: (user) => currentUserId = user.id);
    if (currentUserId == null) return;

    final chatSource = getIt<ChatRemoteSource>();
    final chatId = await chatSource.createOrGetChat(currentUserId!, otherUser.id);

    if (!context.mounted) return;
    context.push(
      '/home/chat/$chatId',
      extra: {'otherUserId': otherUser.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Contacts'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colors.text1, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: colors.text3),
                  prefixIcon: Icon(Icons.search, color: colors.text3),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                onChanged: (val) {
                  context.read<ContactsCubit>().searchContacts(val);
                },
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<ContactsCubit, ContactsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (message) => Center(child: Text(message, style: TextStyle(color: Colors.red))),
            loaded: (users) {
              if (users.isEmpty) {
                return Center(
                  child: Text(
                    _searchController.text.isEmpty ? 'No contacts found' : 'No matching contacts',
                    style: TextStyle(color: colors.text3, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                      child: user.avatarUrl.isEmpty
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(
                      user.name.isNotEmpty ? user.name : user.phone,
                      style: TextStyle(color: colors.text1, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      user.about.isNotEmpty ? user.about : 'Hey there! I am using Sawa.',
                      style: TextStyle(color: colors.text2, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _startChat(context, user),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
