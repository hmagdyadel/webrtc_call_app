import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/sawa_empty_state.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../data/models/story_model.dart';
import '../../viewmodel/story_cubit.dart';
import '../../viewmodel/story_state.dart';
import '../widgets/story_ring_avatar.dart';
import '../widgets/story_creation_sheet.dart';
import 'story_viewer_screen.dart';

class StoriesTab extends StatelessWidget {
  final String userId;
  const StoriesTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Stories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => _showCreationSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<StoryCubit, StoryState>(
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            loaded: (stories, isUploading, uploadProgress) => _buildStoriesList(
              context, 
              stories,
              isUploading: isUploading,
              uploadProgress: uploadProgress,
            ),
            error: (msg) => Center(
              child: Text(msg, style: TextStyle(color: colors.text3)),
            ),
            orElse: () => _buildStoriesList(context, []),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCreationSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStoriesList(
    BuildContext context, 
    List<StoryModel> stories, {
    bool isUploading = false,
    double uploadProgress = 0.0,
  }) {
    final colors = context.sawaColors;
    final grouped = StoryCubit.groupByUser(stories);
    final myStories = grouped[userId] ?? [];
    final otherUsers = grouped.entries.where((e) => e.key != userId).toList();

    // Separate unseen and viewed user stories
    final unseenUsers = <MapEntry<String, List<StoryModel>>>[];
    final viewedUsers = <MapEntry<String, List<StoryModel>>>[];

    for (final entry in otherUsers) {
      final hasUnseen = entry.value.any((s) => !s.isViewedBy(userId));
      if (hasUnseen) {
        unseenUsers.add(entry);
      } else {
        viewedUsers.add(entry);
      }
    }

    return ListView(
      children: [
        // ── My Status ──────────────────────────────────────────
        _MyStatusTile(
          userId: userId,
          myStories: myStories,
          isUploading: isUploading,
          uploadProgress: uploadProgress,
          onAdd: () => _showCreationSheet(context),
          onView: () => _openViewer(context, myStories),
        ),

        // ── Empty state ────────────────────────────────────────
        if (otherUsers.isEmpty && myStories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: SawaEmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'No stories yet',
              subtitle: 'Share moments with your contacts —\nthey disappear after 24 hours',
              actionLabel: '✨ Add Story',
              onAction: () => _showCreationSheet(context),
            ),
          ),

        // ── Recent updates (unseen) ────────────────────────────
        if (unseenUsers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Recent updates',
              style: TextStyle(
                color: colors.text3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...unseenUsers.map((entry) => _StoryUserTile(
                stories: entry.value,
                currentUserId: userId,
                onTap: () => _openViewer(context, entry.value),
              )),
        ],

        // ── Viewed updates ─────────────────────────────────────
        if (viewedUsers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Viewed updates',
              style: TextStyle(
                color: colors.text3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...viewedUsers.map((entry) => _StoryUserTile(
                stories: entry.value,
                currentUserId: userId,
                onTap: () => _openViewer(context, entry.value),
              )),
        ],
      ],
    );
  }

  void _showCreationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<StoryCubit>(),
        child: StoryCreationSheet(userId: userId, parentContext: context),
      ),
    );
  }

  void _openViewer(BuildContext context, List<StoryModel> stories) {
    if (stories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<StoryCubit>(),
          child: StoryViewerScreen(
            stories: stories,
            currentUserId: userId,
          ),
        ),
      ),
    );
  }
}

// ── My Status Row ──────────────────────────────────────────────────────
class _MyStatusTile extends StatelessWidget {
  final String userId;
  final List<StoryModel> myStories;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onAdd;
  final VoidCallback onView;

  const _MyStatusTile({
    required this.userId,
    required this.myStories,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    required this.onAdd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String userName = 'My Status';
        String avatarUrl = '';
        authState.whenOrNull(authenticated: (user) {
          userName = user.name.isNotEmpty ? user.name : 'My Status';
          avatarUrl = user.avatarUrl;
        });

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              StoryRingAvatar(
                avatarUrl: avatarUrl,
                userName: userName,
                stories: myStories,
                currentUserId: userId,
                radius: 26,
                onTap: myStories.isNotEmpty ? onView : onAdd,
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: uploadProgress > 0 ? uploadProgress : null,
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              if (myStories.isEmpty && !isUploading)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.background, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            'My Status',
            style: TextStyle(
              color: colors.text1,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            myStories.isNotEmpty
                ? '${myStories.length} ${myStories.length == 1 ? 'story' : 'stories'} • Tap to view'
                : 'Tap to add a story',
            style: TextStyle(color: colors.text3, fontSize: 13),
          ),
          trailing: myStories.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.add, color: colors.text2),
                  onPressed: onAdd,
                )
              : null,
          onTap: myStories.isNotEmpty ? onView : onAdd,
        );
      },
    );
  }
}

// ── User Story Row ─────────────────────────────────────────────────────
class _StoryUserTile extends StatelessWidget {
  final List<StoryModel> stories;
  final String currentUserId;
  final VoidCallback onTap;

  const _StoryUserTile({
    required this.stories,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    final firstStory = stories.first;
    final latestStory = stories.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: StoryRingAvatar(
        avatarUrl: firstStory.userAvatar,
        userName: firstStory.userName,
        stories: stories,
        currentUserId: currentUserId,
        radius: 26,
        onTap: onTap,
      ),
      title: Text(
        firstStory.userName.isNotEmpty ? firstStory.userName : 'User',
        style: TextStyle(
          color: colors.text1,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        _timeAgo(latestStory.timestamp),
        style: TextStyle(color: colors.text3, fontSize: 13),
      ),
      onTap: onTap,
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
