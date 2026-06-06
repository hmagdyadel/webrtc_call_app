import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;

import '../../../../app/theme/app_colors.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../viewmodel/story_cubit.dart';
import '../screens/text_story_editor.dart';

class StoryCreationSheet extends StatelessWidget {
  final String userId;
  final BuildContext parentContext;

  const StoryCreationSheet({
    super.key,
    required this.userId,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Create Story',
            style: TextStyle(
              color: colors.text1,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OptionTile(
                icon: Icons.text_fields,
                label: 'Text',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _openTextEditor(parentContext);
                },
              ),
              _OptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Photo',
                color: AppColors.accent,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndEditImage(parentContext);
                },
              ),
              _OptionTile(
                icon: Icons.videocam_outlined,
                label: 'Video',
                color: const Color(0xFFFF6B6B),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(parentContext);
                },
              ),
              _OptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                color: const Color(0xFFFFAB40),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(parentContext);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTextEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<StoryCubit>(),
          child: TextStoryEditor(userId: userId),
        ),
      ),
    );
  }

  Future<void> _pickAndEditImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !context.mounted) return;

    final bytes = await File(image.path).readAsBytes();
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _CustomImageEditorScreen(
          bytes: bytes,
          userId: userId,
          parentContext: context,
        ),
      ),
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null || !context.mounted) return;

    final bytes = await File(image.path).readAsBytes();
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _CustomImageEditorScreen(
          bytes: bytes,
          userId: userId,
          parentContext: context,
        ),
      ),
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (video == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _CustomVideoPreviewScreen(
          file: File(video.path),
          userId: userId,
          parentContext: context,
        ),
      ),
    );
  }
}

class _CustomImageEditorScreen extends StatefulWidget {
  final Uint8List bytes;
  final String userId;
  final BuildContext parentContext;

  const _CustomImageEditorScreen({
    required this.bytes,
    required this.userId,
    required this.parentContext,
  });

  @override
  State<_CustomImageEditorScreen> createState() => _CustomImageEditorScreenState();
}

class _CustomImageEditorScreenState extends State<_CustomImageEditorScreen> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmoji = false);
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _uploadImage(BuildContext context, Uint8List editedBytes) async {
    final caption = _captionController.text;
    final tempFile = File(
      '${Directory.systemTemp.path}/story_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(editedBytes);

    if (!widget.parentContext.mounted) return;
    final authState = widget.parentContext.read<AuthCubit>().state;
    final user = authState.whenOrNull(authenticated: (u) => u);
    if (user == null) return;

    widget.parentContext.read<StoryCubit>().uploadImageStory(
          userId: widget.userId,
          userName: user.name,
          userAvatar: user.avatarUrl,
          file: tempFile,
          caption: caption,
        );

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: ProImageEditor.memory(
        widget.bytes,
        configs: ProImageEditorConfigs(
          designMode: ImageEditorDesignMode.material,
          dialogConfigs: DialogConfigs(
            widgets: DialogWidgets(
              loadingDialog: (context, _) => const SizedBox.shrink(),
            ),
          ),
          mainEditor: MainEditorConfigs(
            tools: const [
              SubEditorMode.paint,
              SubEditorMode.text,
              SubEditorMode.cropRotate,
            ],
            style: MainEditorStyle(
              appBarBackground: Theme.of(context).appBarTheme.backgroundColor ?? AppColors.primary,
              background: Colors.black,
            ),
            widgets: MainEditorWidgets(
              bottomBar: (editor, rebuildStream, key) {
                return ReactiveWidget(
                  stream: rebuildStream,
                  builder: (_) => Container(
                    key: key,
                    color: Colors.black,
                    padding: EdgeInsets.only(
                      bottom: _showEmoji ? 0 : MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          if (_showEmoji) {
                                            _focusNode.requestFocus();
                                          } else {
                                            FocusScope.of(context).unfocus();
                                            setState(() => _showEmoji = true);
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _captionController,
                                          focusNode: _focusNode,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            hintText: 'Add a caption...',
                                            hintStyle: TextStyle(color: Colors.white54),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  editor.doneEditing();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showEmoji)
                          SizedBox(
                            height: 250,
                            child: ep.EmojiPicker(
                              textEditingController: _captionController,
                              config: const ep.Config(
                                bottomActionBarConfig: ep.BottomActionBarConfig(showBackspaceButton: false),
                                categoryViewConfig: ep.CategoryViewConfig(
                                  backgroundColor: Colors.black,
                                  iconColorSelected: AppColors.primary,
                                  indicatorColor: AppColors.primary,
                                ),
                                emojiViewConfig: ep.EmojiViewConfig(
                                  backgroundColor: Colors.black,
                                  columns: 7,
                                  emojiSizeMax: 28,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              wrapBody: (editor, rebuildStream, content) {
                return Stack(
                  children: [
                    content,
                    Positioned(
                      top: 120,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.crop, color: Colors.white),
                              onPressed: editor.openCropRotateEditor,
                            ),
                            IconButton(
                              icon: const Icon(Icons.text_fields, color: Colors.white),
                              onPressed: editor.openTextEditor,
                            ),
                            IconButton(
                              icon: const Icon(Icons.brush, color: Colors.white),
                              onPressed: editor.openPaintEditor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List editedBytes) async {
            _uploadImage(context, editedBytes);
          },
        ),
      ),
    );
  }
}

class _CustomVideoPreviewScreen extends StatefulWidget {
  final File file;
  final String userId;
  final BuildContext parentContext;

  const _CustomVideoPreviewScreen({
    required this.file,
    required this.userId,
    required this.parentContext,
  });

  @override
  State<_CustomVideoPreviewScreen> createState() => _CustomVideoPreviewScreenState();
}

class _CustomVideoPreviewScreenState extends State<_CustomVideoPreviewScreen> {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
      
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmoji = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _uploadVideo() {
    final caption = _captionController.text;

    if (!widget.parentContext.mounted) return;
    final authState = widget.parentContext.read<AuthCubit>().state;
    final user = authState.whenOrNull(authenticated: (u) => u);
    if (user == null) return;

    widget.parentContext.read<StoryCubit>().uploadVideoStory(
          userId: widget.userId,
          userName: user.name,
          userAvatar: user.avatarUrl,
          file: widget.file,
          caption: caption,
        );

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          Container(
            color: Colors.black,
            padding: EdgeInsets.only(
              bottom: _showEmoji ? 0 : MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  if (_showEmoji) {
                                    _focusNode.requestFocus();
                                  } else {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _showEmoji = true);
                                  }
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _captionController,
                                  focusNode: _focusNode,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Add a caption...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _uploadVideo();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showEmoji)
                  SizedBox(
                    height: 250,
                    child: ep.EmojiPicker(
                      textEditingController: _captionController,
                      config: const ep.Config(
                        bottomActionBarConfig: ep.BottomActionBarConfig(showBackspaceButton: false),
                        categoryViewConfig: ep.CategoryViewConfig(
                          backgroundColor: Colors.black,
                          iconColorSelected: AppColors.primary,
                          indicatorColor: AppColors.primary,
                        ),
                        emojiViewConfig: ep.EmojiViewConfig(
                          backgroundColor: Colors.black,
                          columns: 7,
                          emojiSizeMax: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option Tile ──────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.text2,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
