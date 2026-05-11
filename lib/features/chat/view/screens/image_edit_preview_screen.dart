import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/sticker_service.dart';

/// Full-screen image preview with editing, cropping, and sticker conversion.
///
/// Displayed before sending an image in chat. The user can:
/// 1. Send as-is
/// 2. Edit (draw, text, emoji, filters)
/// 3. Convert to a rounded sticker
class ImageEditPreviewScreen extends StatefulWidget {
  final File imageFile;
  final String chatId;
  final String currentUserId;
  final String otherUserName;
  final bool otherUserOnline;

  const ImageEditPreviewScreen({
    super.key,
    required this.imageFile,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserName,
    required this.otherUserOnline,
  });

  @override
  State<ImageEditPreviewScreen> createState() => _ImageEditPreviewScreenState();
}

class _ImageEditPreviewScreenState extends State<ImageEditPreviewScreen> {
  late File _currentFile;
  bool _isSending = false;
  bool _isConvertingSticker = false;
  bool _isEditorClosing = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
  }

  // ── Open ProImageEditor ───────────────────────────────────────
  Future<void> _openEditor() async {
    final bytes = await _currentFile.readAsBytes();
    if (!mounted) return;

    _isEditorClosing = false;

    final editorKey = GlobalKey<ProImageEditorState>();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (editorContext) => ProImageEditor.memory(
          bytes,
          key: editorKey,
          configs: const ProImageEditorConfigs(
            designMode: ImageEditorDesignMode.material,
          ),
          callbacks: ProImageEditorCallbacks(
            mainEditorCallbacks: MainEditorCallbacks(
              onAfterViewInit: () {
                // WhatsApp-like: Open crop editor automatically on start
                editorKey.currentState?.openCropRotateEditor();
              },
            ),
            onImageEditingComplete: (Uint8List editedBytes) async {
              if (_isEditorClosing) return;
              _isEditorClosing = true;

              final dir = await getTemporaryDirectory();
              final editedFile = File(
                '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
              );
              await editedFile.writeAsBytes(editedBytes);
              
              if (mounted) {
                // Return result to the push call below
                Navigator.pop(editorContext, {
                  'file': editedFile,
                  'isSticker': false,
                });
              }
            },
            onCloseEditor: (_) {
              if (_isEditorClosing) return;
              _isEditorClosing = true;
              Navigator.pop(editorContext);
            },
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      // If we got a result from the editor, return it to ChatScreen immediately
      Navigator.pop(context, result);
    }
  }

  // ── Convert to sticker (rounded corners PNG) ──────────────────
  Future<void> _convertToSticker() async {
    setState(() => _isConvertingSticker = true);

    try {
      final bytes = await _currentFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Cannot decode image');

      // Resize to max 512px
      final resized = img.copyResize(
        decoded,
        width: decoded.width > 512 ? 512 : decoded.width,
      );

      // Apply rounded corners
      final stickerImage = _applyRoundedCorners(resized, radius: 32);

      final dir = await getTemporaryDirectory();
      final stickerFile = File(
        '${dir.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await stickerFile.writeAsBytes(img.encodePng(stickerImage));

      setState(() {
        _currentFile = stickerFile;
        _isConvertingSticker = false;
      });

      // Send as sticker immediately
      await _sendImage(asSticker: true);
    } catch (e) {
      setState(() => _isConvertingSticker = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحويل الصورة لستيكر'),
            backgroundColor: AppColors.missed,
          ),
        );
      }
    }
  }

  img.Image _applyRoundedCorners(img.Image source, {required int radius}) {
    final result = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        if (_isInsideRoundedCorner(x, y, source.width, source.height, radius)) {
          result.setPixel(x, y, pixel);
        } else {
          result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        }
      }
    }
    return result;
  }

  bool _isInsideRoundedCorner(int x, int y, int w, int h, int r) {
    if (x >= r && x < w - r) return true;
    if (y >= r && y < h - r) return true;

    if (x < r && y < r) {
      return (x - r) * (x - r) + (y - r) * (y - r) <= r * r;
    }
    if (x >= w - r && y < r) {
      return (x - (w - r)) * (x - (w - r)) + (y - r) * (y - r) <= r * r;
    }
    if (x < r && y >= h - r) {
      return (x - r) * (x - r) + (y - (h - r)) * (y - (h - r)) <= r * r;
    }
    if (x >= w - r && y >= h - r) {
      return (x - (w - r)) * (x - (w - r)) + (y - (h - r)) * (y - (h - r)) <= r * r;
    }
    return false;
  }

  // ── Send image or sticker ─────────────────────────────────────
  Future<void> _sendImage({bool asSticker = false}) async {
    setState(() => _isSending = true);

    File finalFile = _currentFile;

    if (asSticker) {
      try {
        // Save permanently to the sticker gallery for future reuse
        finalFile = await getIt<StickerService>().saveSticker(_currentFile);
      } catch (e) {
        debugPrint('Error saving sticker to gallery: $e');
        // Fallback to temp file if saving fails
      }
    }

    // Pop back to ChatScreen and return result
    if (!mounted) return;
    Navigator.pop(context, {
      'file': finalFile,
      'isSticker': asSticker,
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Image Preview Area ─────────────────────────────────────
          Positioned.fill(
            child: _isConvertingSticker
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : GestureDetector(
                    onTap: _openEditor,
                    child: Hero(
                      tag: widget.imageFile.path,
                      child: Image.file(
                        _currentFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),

          // ── Top Bar ──────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.otherUserOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Action Bar ──────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: _openEditor,
                ),
                _buildActionButton(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Sticker',
                  onTap: _convertToSticker,
                ),
                const SizedBox(width: 40), // Spacer for the FAB-like send button
              ],
            ),
          ),

          // ── Send Button ───────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 10,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.accent,
              onPressed: _isSending ? null : () => _sendImage(),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 25,
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
