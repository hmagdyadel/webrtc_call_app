import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../../stories/data/models/story_model.dart';
import '../../../stories/view/screens/story_viewer_screen.dart';
import '../../../stories/view/widgets/story_ring_avatar.dart';
import '../../../stories/viewmodel/story_cubit.dart';
import '../../../stories/viewmodel/story_state.dart';
import 'chat_media_screen.dart';

class ContactProfileScreen extends StatelessWidget {
  final String userId;
  final String? chatId;

  const ContactProfileScreen({super.key, required this.userId, this.chatId});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'User not found',
                style: TextStyle(color: colors.text3),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final user = UserModel.fromJson({...data, 'id': snapshot.data!.id});

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    user.name.isNotEmpty ? user.name : user.phone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                  background: _buildAvatarBackground(context, user),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context: context,
                      title: 'About',
                      content: user.about.isNotEmpty ? user.about : 'Hey there! I am using Sawa.',
                      icon: Icons.info_outline,
                    ),
                    _buildInfoCard(
                      context: context,
                      title: 'Phone Number',
                      content: user.phone,
                      icon: Icons.phone_android,
                    ),
                    const SizedBox(height: 16),
                    _buildActionsCard(context, user),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarBackground(BuildContext context, UserModel user) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUserId = authState.maybeWhen(
          authenticated: (currentUser) => currentUser.id,
          orElse: () => '',
        );

        return BlocBuilder<StoryCubit, StoryState>(
          builder: (context, storyState) {
            List<StoryModel> userStories = [];
            storyState.whenOrNull(
              loaded: (stories, _, _) {
                userStories = stories.where((s) => s.userId == user.id).toList();
              },
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                if (user.avatarUrl.isNotEmpty)
                  Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                  )
                else
                  Container(color: AppColors.primary),
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: Colors.black.withValues(alpha: 0.3)),
                  ),
                ),
                Center(
                  child: StoryRingAvatar(
                    avatarUrl: user.avatarUrl,
                    userName: user.name.isNotEmpty ? user.name : user.phone,
                    stories: userStories,
                    currentUserId: currentUserId,
                    radius: 110,
                    onTap: userStories.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => StoryViewerScreen(
                                  stories: userStories,
                                  currentUserId: currentUserId,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
  }) {
    final colors = context.sawaColors;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.text3,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: colors.text1,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, UserModel user) {
    final colors = context.sawaColors;
    
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser = authState.whenOrNull(authenticated: (u) => u);
        if (currentUser == null) return const SizedBox.shrink();

        final isBlocked = currentUser.blockedUsers.contains(user.id);
        
        return StatefulBuilder(
          builder: (context, setState) {
            bool isMuted = currentUser.mutedUsers.contains(user.id);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    context: context,
                    title: 'Media, links, and docs',
                    icon: Icons.photo_library_outlined,
                    onTap: () {
                      if (chatId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatMediaScreen(chatId: chatId!)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat not found', style: TextStyle(color: colors.text1)), backgroundColor: colors.surface));
                      }
                    },
                  ),
                  Divider(color: colors.divider),
                  _buildActionTile(
                    context: context,
                    title: 'Search in chat',
                    icon: Icons.search,
                    onTap: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  Divider(color: colors.divider),
                  _buildActionTile(
                    context: context,
                    title: isMuted ? 'Unmute notifications' : 'Mute notifications',
                    icon: isMuted ? Icons.notifications_off : Icons.notifications_active_outlined,
                    onTap: () async {
                      await context.read<AuthCubit>().toggleMute(user.id);
                      final nowMuted = !isMuted;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(nowMuted ? 'Notifications muted' : 'Notifications unmuted', style: TextStyle(color: colors.text1)),
                            backgroundColor: colors.surface,
                          ),
                        );
                      }
                    },
                  ),
                  Divider(color: colors.divider),
                  _buildActionTile(
                    context: context,
                    title: isBlocked ? 'Unblock ${user.name.isNotEmpty ? user.name : 'User'}' : 'Block ${user.name.isNotEmpty ? user.name : 'User'}',
                    icon: Icons.block,
                    color: isBlocked ? colors.text2 : Colors.red,
                    onTap: () async {
                      if (isBlocked) {
                        await context.read<AuthCubit>().unblockUser(user.id);
                      } else {
                        await context.read<AuthCubit>().blockUser(user.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colors = context.sawaColors;
    final iconColor = color ?? colors.text2;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color ?? colors.text1,
                fontSize: 16,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
