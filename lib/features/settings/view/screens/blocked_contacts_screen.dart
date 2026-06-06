import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';

class BlockedContactsScreen extends StatelessWidget {
  const BlockedContactsScreen({super.key});

  Future<List<UserModel>> _getBlockedUsers(List<String> blockedIds) async {
    if (blockedIds.isEmpty) return [];
    
    // Firestore whereIn has a limit of 10. If there are more than 10 blocked users,
    // we would need to batch the requests. For simplicity here, we assume <= 10.
    // To be perfectly safe, we fetch them individually or chunk them.
    List<UserModel> users = [];
    for (String id in blockedIds) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (doc.exists && doc.data() != null) {
        users.add(UserModel.fromJson({...doc.data()!, 'id': doc.id}));
      }
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Blocked contacts'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return state.maybeWhen(
            authenticated: (currentUser) {
              if (currentUser.blockedUsers.isEmpty) {
                return Center(
                  child: Text(
                    'No blocked contacts',
                    style: TextStyle(color: colors.text3, fontSize: 16),
                  ),
                );
              }

              return FutureBuilder<List<UserModel>>(
                future: _getBlockedUsers(currentUser.blockedUsers),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading blocked contacts', style: TextStyle(color: Colors.red)));
                  }

                  final blockedUsers = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = blockedUsers[index];
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
                          style: TextStyle(color: colors.text1),
                        ),
                        onTap: () {
                          _showUnblockDialog(context, user);
                        },
                      );
                    },
                  );
                },
              );
            },
            orElse: () => const SizedBox(),
          );
        },
      ),
    );
  }

  void _showUnblockDialog(BuildContext context, UserModel user) {
    final colors = context.sawaColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        content: Text('Unblock ${user.name.isNotEmpty ? user.name : user.phone}?', style: TextStyle(color: colors.text1)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().unblockUser(user.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name.isNotEmpty ? user.name : user.phone} has been unblocked', style: TextStyle(color: colors.text1)),
                  backgroundColor: colors.surface,
                ),
              );
            },
            child: Text('UNBLOCK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
