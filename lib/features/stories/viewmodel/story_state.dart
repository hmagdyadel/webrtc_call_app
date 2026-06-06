import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/story_model.dart';

part 'story_state.freezed.dart';

@freezed
class StoryState with _$StoryState {
  const factory StoryState.initial() = _Initial;
  const factory StoryState.loading() = _Loading;
  const factory StoryState.loaded(
    List<StoryModel> stories, {
    @Default(false) bool isUploading,
    @Default(0.0) double uploadProgress,
  }) = _Loaded;
  const factory StoryState.error(String message) = _Error;
}

