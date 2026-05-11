import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/sticker_service.dart';

class StickerPicker extends StatefulWidget {
  final Function(String path) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  List<String> _stickerPaths = [];

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  void _loadStickers() {
    setState(() {
      _stickerPaths = getIt<StickerService>().getSavedStickerPaths();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'ملصقاتي',
                  style: TextStyle(
                    color: colors.text1,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_stickerPaths.isNotEmpty)
                  Text(
                    '${_stickerPaths.length} ملصق',
                    style: TextStyle(color: colors.text3, fontSize: 13),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Grid
          Expanded(
            child: _stickerPaths.isEmpty
                ? _buildEmptyState(colors)
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _stickerPaths.length,
                    itemBuilder: (context, index) {
                      final path = _stickerPaths[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onStickerSelected(path);
                        },
                        onLongPress: () => _confirmDelete(path),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.divider, width: 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => Icon(
                                Icons.image_not_supported_outlined,
                                color: colors.text3,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SawaColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 48, color: colors.divider),
          const SizedBox(height: 16),
          Text(
            'لا يوجد ملصقات بعد',
            style: TextStyle(color: colors.text2, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'حول أي صورة لملصق لتبدأ مجموعتك',
            style: TextStyle(color: colors.text3, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String path) async {
    final colors = context.sawaColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: Text('حذف الملصق؟', style: TextStyle(color: colors.text1)),
        content: Text('هل تريد حذف هذا الملصق من مجموعتك؟', style: TextStyle(color: colors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: colors.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await getIt<StickerService>().deleteSticker(path);
      _loadStickers();
    }
  }
}
