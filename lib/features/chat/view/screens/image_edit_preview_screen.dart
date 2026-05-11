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

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
  }

  // ── Open ProImageEditor ───────────────────────────────────────
  Future<void> _openEditor() async {
    final bytes = await _currentFile.readAsBytes();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          bytes,
          configs: const ProImageEditorConfigs(
            designMode: ImageEditorDesignMode.material,
          ),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {
              final dir = await getTemporaryDirectory();
              final editedFile = File(
                '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
              );
              await editedFile.writeAsBytes(editedBytes);
              if (mounted) {
                // Immediately return the edited file to ChatScreen to be sent
                Navigator.pop(context); // Close editor
                Navigator.pop(context, { // Close preview screen and return result
                  'file': editedFile,
                  'isSticker': false,
                });
              }
            },
            onCloseEditor: (_) {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
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
        if (_isInRoundedCorner(x, y, source.width, source.height, radius)) {
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          result.setPixel(x, y, source.getPixel(x, y));
        }
      }
    }
    return result;
  }

  bool _isInRoundedCorner(int x, int y, int w, int h, int r) {
    if (x < r && y < r) {
      return (x - r) * (x - r) + (y - r) * (y - r) > r * r;
    }
    if (x >= w - r && y < r) {
      return (x - (w - r)) * (x - (w - r)) + (y - r) * (y - r) > r * r;
    }
    if (x < r && y >= h - r) {
      return (x - r) * (x - r) + (y - (h - r)) * (y - (h - r)) > r * r;
    }
    if (x >= w - r && y >= h - r) {
      return (x - (w - r)) * (x - (w - r)) + (y - (h - r)) * (y - (h - r)) > r * r;
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
    final colors = context.sawaColors;
    final nameInitial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                nameInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName
                      : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.otherUserOnline ? 'متصل الآن' : 'آخر ظهور مؤخراً',
                  style: TextStyle(
                    color: widget.otherUserOnline
                        ? AppColors.accent
                        : colors.text3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isSending)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.accent),
              onPressed: () => _sendImage(asSticker: false),
              tooltip: 'إرسال',
            ),
        ],
      ),
      body: Column(
        children: [
          // Main image preview
          Expanded(
            child: Container(
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    _currentFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Bottom action bar
          Container(
            color: colors.card,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Edit button
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'تعديل',
                    color: AppColors.primaryLight,
                    onTap: _openEditor,
                  ),

                  // Crop button (opens editor which has crop)
                  _ActionButton(
                    icon: Icons.crop,
                    label: 'اقتصاص',
                    color: AppColors.accent,
                    onTap: _openEditor,
                  ),

                  // Sticker conversion
                  _ActionButton(
                    icon: Icons.auto_awesome,
                    label: 'ستيكر',
                    color: const Color(0xFFFFB347),
                    isLoading: _isConvertingSticker,
                    onTap: _isConvertingSticker ? null : _convertToSticker,
                  ),

                  // Send button
                  _ActionButton(
                    icon: Icons.send_rounded,
                    label: 'إرسال',
                    color: AppColors.primary,
                    isLoading: _isSending,
                    isPrimary: true,
                    onTap: _isSending ? null : () => _sendImage(asSticker: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable action button ──────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: isPrimary ? Colors.white : color,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    icon,
                    color: isPrimary ? Colors.white : color,
                    size: 22,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
