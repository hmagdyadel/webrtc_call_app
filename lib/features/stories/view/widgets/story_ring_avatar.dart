import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/story_model.dart';

/// A circular avatar with a segmented story ring around it.
///
/// The ring is divided into N segments (one per story). Each segment is
/// either a gradient (unseen) or grey (already viewed by [currentUserId]).
/// When there are no stories, it renders a plain [CircleAvatar].
class StoryRingAvatar extends StatelessWidget {
  final String avatarUrl;
  final String userName;
  final List<StoryModel> stories;
  final String currentUserId;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const StoryRingAvatar({
    super.key,
    required this.avatarUrl,
    required this.userName,
    required this.stories,
    required this.currentUserId,
    this.radius = 24,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    final avatar = CircleAvatar(
      radius: radius - (stories.isNotEmpty ? 3 : 0),
      backgroundColor: AppColors.primary,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? (userName.isNotEmpty && !RegExp(r'^[0-9+]+$').hasMatch(userName)
              ? Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(Icons.person, color: Colors.white, size: radius * 0.8))
          : null,
    );

    if (stories.isEmpty) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: avatar,
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: CustomPaint(
        painter: _StoryRingPainter(
          storyCount: stories.length,
          viewedStatuses: stories.map((s) => s.isViewedBy(currentUserId)).toList(),
          ringColor: colors.divider,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: avatar,
        ),
      ),
    );
  }
}

class _StoryRingPainter extends CustomPainter {
  final int storyCount;
  final List<bool> viewedStatuses;
  final Color ringColor;

  static const double _ringWidth = 2.5;
  static const double _gapAngle = 0.12; // Gap between segments in radians

  _StoryRingPainter({
    required this.storyCount,
    required this.viewedStatuses,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    if (storyCount == 0) return;

    // Calculate the angle per segment
    final totalGap = storyCount > 1 ? _gapAngle * storyCount : 0.0;
    final totalArc = 2 * pi - totalGap;
    final arcPerSegment = totalArc / storyCount;

    // Start from the top (-π/2)
    double startAngle = -pi / 2;

    for (int i = 0; i < storyCount; i++) {
      final isViewed = viewedStatuses[i];

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth
        ..strokeCap = StrokeCap.round;

      if (isViewed) {
        // Grey for viewed stories
        paint.color = ringColor;
      } else {
        // Gradient for unseen stories
        final rect = Rect.fromCircle(center: center, radius: outerRadius);
        paint.shader = const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius - _ringWidth / 2),
        startAngle,
        arcPerSegment,
        false,
        paint,
      );

      startAngle += arcPerSegment + (storyCount > 1 ? _gapAngle : 0);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryRingPainter oldDelegate) {
    return oldDelegate.storyCount != storyCount ||
        oldDelegate.viewedStatuses != viewedStatuses;
  }
}
