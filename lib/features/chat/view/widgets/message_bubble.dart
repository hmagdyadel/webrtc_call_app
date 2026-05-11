import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/message_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/sticker_service.dart';
import 'audio_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSent;
  final double? uploadProgress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == 'sticker') {
      return _buildSticker(context);
    }

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isSent ? 60 : 12,
          right: isSent ? 12 : 60,
          top: 4,
          bottom: 4,
        ),
        padding: message.type == 'image' || message.type == 'video'
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSent ? AppColors.primary : context.sawaColors.surface,
          border: isSent
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMessageContent(context),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isSent
                        ? Colors.white.withValues(alpha: 0.65)
                        : context.sawaColors.text3,
                    fontSize: 11,
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSticker(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showStickerOptions(context),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isSent ? 60 : 12,
            right: isSent ? 12 : 60,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.mediaUrl != null)
                CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              else
                const Icon(Icons.broken_image, size: 120, color: Colors.grey),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(color: context.sawaColors.text3, fontSize: 11),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final colors = context.sawaColors;
    final textColor = isSent ? Colors.white : colors.text1;
    final isUploading = message.status == 'uploading';
    final localPath = message.metadata?['localPath'] as String?;

    switch (message.type) {
      case 'image':
        return InkWell(
          onTap: () {
            if (!isUploading && (message.mediaUrl != null || localPath != null) && rootNavigatorKey.currentContext != null) {
              rootNavigatorKey.currentContext!.push(
                '/home/chat/image-preview',
                extra: message.mediaUrl ?? localPath,
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.mediaUrl != null || localPath != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: message.mediaUrl != null
                          ? CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                height: 150,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : Image.file(
                              File(localPath!),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (isUploading)
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: uploadProgress,
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            if (uploadProgress != null)
                              Text(
                                '${(uploadProgress! * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        );
      case 'video':
        return InkWell(
          onTap: () {
            if (!isUploading && message.mediaUrl != null && rootNavigatorKey.currentContext != null) {
              rootNavigatorKey.currentContext!.push('/home/chat/video-player', extra: message.mediaUrl);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                      ),
                    ),
                  ),
                  if (isUploading)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        value: uploadProgress,
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                ],
              ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        );
      case 'file':
        final fileName = message.metadata?['fileName'] ?? 'Document';
        return InkWell(
          onTap: () async {
            if (message.mediaUrl != null) {
              final url = Uri.parse(message.mediaUrl!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSent ? Colors.white24 : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.insert_drive_file, color: textColor, size: 24),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  fileName,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case 'location':
        return InkWell(
          onTap: () async {
            final lat = message.metadata?['latitude'];
            final lng = message.metadata?['longitude'];
            if (lat != null && lng != null) {
              final url = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
              if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                final fallback = Uri.parse('https://maps.google.com/?q=$lat,$lng');
                if (await canLaunchUrl(fallback)) {
                    await launchUrl(fallback, mode: LaunchMode.externalApplication);
                }
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSent ? Colors.white.withValues(alpha: 0.12) : context.sawaColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, size: 22, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${message.metadata?['latitude']?.toStringAsFixed(5) ?? '--'}, '
                        '${message.metadata?['longitude']?.toStringAsFixed(5) ?? '--'}',
                        style: TextStyle(color: textColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.map, size: 16, color: textColor.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    'Location',
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        );
      case 'audio':
        return AudioPlayerWidget(
          url: message.mediaUrl ?? '',
          isSent: isSent,
          localPath: localPath,
          isUploading: isUploading,
          uploadProgress: uploadProgress,
        );
      case 'contact':
        final contactName = message.metadata?['name'] ?? 'Contact';
        final contactPhone = message.metadata?['phone'] ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSent ? Colors.white24 : AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: textColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contactName,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contactPhone.isNotEmpty)
                        Text(
                          contactPhone,
                          style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  final url = Uri.parse('tel:$contactPhone');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Text(
                  'Call Contact',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      case 'text':
      default:
        return Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            height: 1.4,
          ),
        );
    }
  }

  Future<void> _showStickerOptions(BuildContext context) async {
    final colors = context.sawaColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined, color: AppColors.primary),
              title: Text('حفظ في ملصقاتي', style: TextStyle(color: colors.text1)),
              onTap: () {
                Navigator.pop(context);
                _saveStickerToGallery(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStickerToGallery(BuildContext context) async {
    if (message.mediaUrl == null) return;

    try {
      final file = await DefaultCacheManager().getSingleFile(message.mediaUrl!);
      await getIt<StickerService>().saveSticker(file);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحفظ في ملصقاتك بنجاح ✅'),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ الملصق')),
        );
      }
    }
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: AppColors.accent);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.white.withValues(alpha: 0.65));
      case 'uploading':
        return Icon(Icons.schedule, size: 12, color: Colors.white.withValues(alpha: 0.65));
      case 'sent':
      default:
        return Icon(Icons.check, size: 14, color: Colors.white.withValues(alpha: 0.65));
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat.Hm().format(time);
  }
}
