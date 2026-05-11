import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class StickerService {
  static const String _stickersKey = 'saved_stickers_list';
  final SharedPreferences _prefs;

  StickerService(this._prefs);

  Future<Directory> get _stickersDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final stickerDir = Directory(p.join(appDir.path, 'stickers'));
    if (!await stickerDir.exists()) {
      await stickerDir.create(recursive: true);
    }
    return stickerDir;
  }

  /// Saves a new sticker from a temporary file to persistent storage.
  /// Returns the persistent File object.
  Future<File> saveSticker(File tempFile) async {
    final dir = await _stickersDir;
    final fileName = 'sticker_${DateTime.now().millisecondsSinceEpoch}.png';
    final savedFile = await tempFile.copy(p.join(dir.path, fileName));

    // Update the list in preferences
    final currentList = _prefs.getStringList(_stickersKey) ?? [];
    currentList.insert(0, savedFile.path); // Newest first
    await _prefs.setStringList(_stickersKey, currentList);

    return savedFile;
  }

  /// Gets all saved sticker file paths.
  List<String> getSavedStickerPaths() {
    return _prefs.getStringList(_stickersKey) ?? [];
  }

  /// Removes a sticker from storage.
  Future<void> deleteSticker(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final currentList = _prefs.getStringList(_stickersKey) ?? [];
    currentList.remove(path);
    await _prefs.setStringList(_stickersKey, currentList);
  }
}
