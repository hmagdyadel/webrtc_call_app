import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryMediaType { text, image, video }

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final StoryMediaType type;
  final DateTime timestamp;
  final List<String> viewers;

  // For image/video stories
  final String? mediaUrl;

  // For text stories & captions on image/video
  final String? text;
  final String? backgroundColor; // Hex color for text story backgrounds
  final String? fontFamily;      // Font choice for text stories

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.type,
    required this.timestamp,
    this.viewers = const [],
    this.mediaUrl,
    this.text,
    this.backgroundColor,
    this.fontFamily,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'viewers': viewers,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (text != null) 'text': text,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (fontFamily != null) 'fontFamily': fontFamily,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      type: StoryMediaType.values.byName(map['type'] ?? 'image'),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      viewers: List<String>.from(map['viewers'] ?? []),
      mediaUrl: map['mediaUrl'],
      text: map['text'],
      backgroundColor: map['backgroundColor'],
      fontFamily: map['fontFamily'],
    );
  }

  /// Whether a given user has already viewed this story
  bool isViewedBy(String uid) => viewers.contains(uid);
}
