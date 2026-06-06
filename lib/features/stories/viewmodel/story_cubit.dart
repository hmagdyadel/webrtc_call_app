import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import '../data/models/story_model.dart';
import 'story_state.dart';

@injectable
class StoryCubit extends Cubit<StoryState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  StreamSubscription? _storiesSubscription;

  StoryCubit() : super(const StoryState.initial());

  List<StoryModel> _cachedStories = [];

  /// Load all stories from the last 24 hours (real-time)
  void loadStories() {
    emit(const StoryState.loading());

    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );

    _storiesSubscription?.cancel();
    _storiesSubscription = _firestore
        .collection('stories')
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _cachedStories = snapshot.docs
            .map((doc) => StoryModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
        
        final currentState = state;
        final isUploading = currentState.maybeWhen(
          loaded: (_, isUp, _) => isUp,
          orElse: () => false,
        );
        final uploadProgress = currentState.maybeWhen(
          loaded: (_, _, prog) => prog,
          orElse: () => 0.0,
        );
        
        emit(StoryState.loaded(
          _cachedStories,
          isUploading: isUploading,
          uploadProgress: uploadProgress,
        ));
      },
      onError: (e) {
        debugPrint('StoryCubit error: $e');
        emit(StoryState.error(e.toString()));
      },
    );
  }

  /// Upload a text-only story (no media file)
  Future<void> uploadTextStory({
    required String userId,
    required String userName,
    required String userAvatar,
    required String text,
    required String backgroundColor,
    String? fontFamily,
  }) async {
    try {
      emit(StoryState.loaded(_cachedStories, isUploading: true, uploadProgress: 0.0));

      final storyId = _firestore.collection('stories').doc().id;
      final story = StoryModel(
        id: storyId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        type: StoryMediaType.text,
        timestamp: DateTime.now(),
        text: text,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());
      // Stream listener will update the state automatically, but we need to reset uploading flag
      emit(StoryState.loaded(_cachedStories, isUploading: false, uploadProgress: 0.0));
    } catch (e) {
      emit(StoryState.error(e.toString()));
    }
  }

  /// Upload an image story with optional caption
  Future<void> uploadImageStory({
    required String userId,
    required String userName,
    required String userAvatar,
    required File file,
    String? caption,
  }) async {
    try {
      emit(StoryState.loaded(_cachedStories, isUploading: true, uploadProgress: 0.0));

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      final ref = _storage.ref().child('stories').child(fileName);

      final uploadTask = ref.putFile(file);

      // Track upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        emit(StoryState.loaded(_cachedStories, isUploading: true, uploadProgress: progress));
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final storyId = _firestore.collection('stories').doc().id;
      final story = StoryModel(
        id: storyId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        type: StoryMediaType.image,
        timestamp: DateTime.now(),
        mediaUrl: downloadUrl,
        text: caption,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());
      emit(StoryState.loaded(_cachedStories, isUploading: false, uploadProgress: 0.0));
    } catch (e) {
      emit(StoryState.error(e.toString()));
    }
  }

  /// Upload a video story with optional caption
  Future<void> uploadVideoStory({
    required String userId,
    required String userName,
    required String userAvatar,
    required File file,
    String? caption,
  }) async {
    try {
      emit(StoryState.loaded(_cachedStories, isUploading: true, uploadProgress: 0.0));

      final fileName = 'vid_${DateTime.now().millisecondsSinceEpoch}_$userId';
      final ref = _storage.ref().child('stories').child(fileName);

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        emit(StoryState.loaded(_cachedStories, isUploading: true, uploadProgress: progress));
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final storyId = _firestore.collection('stories').doc().id;
      final story = StoryModel(
        id: storyId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        type: StoryMediaType.video,
        timestamp: DateTime.now(),
        mediaUrl: downloadUrl,
        text: caption,
      );

      await _firestore.collection('stories').doc(storyId).set(story.toMap());
      emit(StoryState.loaded(_cachedStories, isUploading: false, uploadProgress: 0.0));
    } catch (e) {
      emit(StoryState.error(e.toString()));
    }
  }

  /// Mark a story as viewed by adding the user's ID to the viewers array
  Future<void> markStoryAsViewed(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking story as viewed: $e');
    }
  }

  /// Delete a story (own stories only)
  Future<void> deleteStory(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Delete media file from Storage if it exists
        final mediaUrl = data['mediaUrl'] as String?;
        if (mediaUrl != null && mediaUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(mediaUrl).delete();
          } catch (e) {
            debugPrint('Error deleting story media: $e');
          }
        }
        await _firestore.collection('stories').doc(storyId).delete();
      }
    } catch (e) {
      debugPrint('Error deleting story: $e');
    }
  }

  /// Group stories by user, returning a map of userId to a list of StoryModel
  /// sorted with the most recent story per user first
  static Map<String, List<StoryModel>> groupByUser(List<StoryModel> stories) {
    final map = <String, List<StoryModel>>{};
    for (final story in stories) {
      map.putIfAbsent(story.userId, () => []).add(story);
    }
    return map;
  }

  @override
  Future<void> close() {
    _storiesSubscription?.cancel();
    return super.close();
  }
}
