import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/story_model.dart';
import '../../viewmodel/story_cubit.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final String currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;
  double _progress = 0;
  Timer? _timer;
  bool _isPaused = false;
  VideoPlayerController? _videoController;

  static const int _imageDurationMs = 5000;
  static const int _tickIntervalMs = 50;

  @override
  void initState() {
    super.initState();
    _showStory(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _showStory(int index) {
    if (index >= widget.stories.length) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentIndex = index;
      _progress = 0;
      _isPaused = false;
    });

    // Mark as viewed
    final story = widget.stories[index];
    if (!story.isViewedBy(widget.currentUserId)) {
      context.read<StoryCubit>().markStoryAsViewed(story.id, widget.currentUserId);
    }

    // Dispose previous video controller
    _videoController?.dispose();
    _videoController = null;

    if (story.type == StoryMediaType.video && story.mediaUrl != null) {
      _initVideoPlayer(story.mediaUrl!);
    } else {
      _startImageTimer();
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    _timer?.cancel();
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      controller.play();
      setState(() {});

      // Timer based on video duration
      final duration = controller.value.duration.inMilliseconds;
      _timer = Timer.periodic(
        const Duration(milliseconds: _tickIntervalMs),
        (timer) {
          if (_isPaused) return;
          if (!mounted) {
            timer.cancel();
            return;
          }
          final position = controller.value.position.inMilliseconds;
          setState(() {
            _progress = duration > 0 ? position / duration : 0;
            if (_progress >= 1.0) {
              _nextStory();
            }
          });
        },
      );
    } catch (e) {
      // Fall back to image timer if video fails
      _startImageTimer();
    }
  }

  void _startImageTimer() {
    _timer?.cancel();
    _progress = 0;
    _timer = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (timer) {
        if (_isPaused) return;
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _progress += _tickIntervalMs / _imageDurationMs;
          if (_progress >= 1.0) {
            _nextStory();
          }
        });
      },
    );
  }

  void _nextStory() {
    _timer?.cancel();
    if (_currentIndex < widget.stories.length - 1) {
      _showStory(_currentIndex + 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    _timer?.cancel();
    if (_currentIndex > 0) {
      _showStory(_currentIndex - 1);
    } else {
      _showStory(0); // Restart first story
    }
  }

  void _pause() {
    setState(() => _isPaused = true);
    _videoController?.pause();
  }

  void _resume() {
    setState(() => _isPaused = false);
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        child: Stack(
          children: [
            // ── Story Content ──────────────────────────────────
            Positioned.fill(child: _buildStoryContent(story)),

            // ── Tap zones ──────────────────────────────────────
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(onTap: _previousStory),
                  ),
                  Expanded(
                    child: GestureDetector(onTap: _nextStory),
                  ),
                ],
              ),
            ),

            // ── Progress bars ──────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: index < _currentIndex
                              ? 1.0
                              : (index == _currentIndex ? _progress : 0.0),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── User info header ───────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    backgroundImage: story.userAvatar.isNotEmpty
                        ? NetworkImage(story.userAvatar)
                        : null,
                    child: story.userAvatar.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.userId == widget.currentUserId
                              ? 'My Status'
                              : story.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _timeAgo(story.timestamp),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button for own stories
                  if (story.userId == widget.currentUserId)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      onPressed: () => _deleteStory(story),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Caption overlay ────────────────────────────────
            if (story.text != null &&
                story.text!.isNotEmpty &&
                story.type != StoryMediaType.text) // Text stories render text as main content
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story.text!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

            // ── Reply bar (for other users' stories) ───────────
            if (story.userId != widget.currentUserId)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _replyToStory(story),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white38),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Reply to ${story.userName}...',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    switch (story.type) {
      case StoryMediaType.text:
        return _buildTextStory(story);
      case StoryMediaType.image:
        return _buildImageStory(story);
      case StoryMediaType.video:
        return _buildVideoStory(story);
    }
  }

  Widget _buildTextStory(StoryModel story) {
    // Parse background color
    Color bgColor = AppColors.primary;
    if (story.backgroundColor != null) {
      try {
        final hex = story.backgroundColor!.replaceAll('#', '');
        bgColor = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }

    // Determine font style
    TextStyle textStyle;
    switch (story.fontFamily) {
      case 'Playfair Display':
        textStyle = GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        );
      case 'Space Mono':
        textStyle = GoogleFonts.spaceMono(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        );
      case 'Dancing Script':
        textStyle = GoogleFonts.dancingScript(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        );
      default:
        textStyle = GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        story.text ?? '',
        textAlign: TextAlign.center,
        style: textStyle,
      ),
    );
  }

  Widget _buildImageStory(StoryModel story) {
    if (story.mediaUrl == null) return const SizedBox();
    return CachedNetworkImage(
      imageUrl: story.mediaUrl!,
      fit: BoxFit.contain,
      placeholder: (ctx, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (ctx, url, error) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
      ),
    );
  }

  Widget _buildVideoStory(StoryModel story) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  void _deleteStory(StoryModel story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<StoryCubit>().deleteStory(story.id);
              if (widget.stories.length <= 1) {
                Navigator.pop(context);
              } else {
                _nextStory();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _replyToStory(StoryModel story) {
    // Navigate to the chat with this user
    // Find or create the chat, then navigate
    _pause();
    Navigator.pop(context); // Close viewer first

    // Navigate to new chat / existing chat
    context.push('/home/chat/new', extra: {
      'otherUserId': story.userId,
    });
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
