import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/sawa_empty_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../viewmodel/message_cubit.dart';
import '../../viewmodel/message_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sticker_picker.dart';
import 'contact_profile_screen.dart';
import 'image_edit_preview_screen.dart';
import '../../../stories/viewmodel/story_cubit.dart';
import '../../../stories/viewmodel/story_state.dart';
import '../../../stories/data/models/story_model.dart';
import '../../../stories/view/widgets/story_ring_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final MessageCubit _messageCubit;

  String _otherUserName = '';
  String _otherUserAvatar = '';
  String _otherUserAbout = '';
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;
  
  Timer? _toggleTimer;
  bool _showAbout = true;
  
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final List<int> _matchIndices = [];
  int _currentMatchIndex = 0;
  final Map<String, GlobalKey> _messageKeys = {};

  GlobalKey _getKey(String id) {
    if (!_messageKeys.containsKey(id)) {
      _messageKeys[id] = GlobalKey();
    }
    return _messageKeys[id]!;
  }

  void _updateSearchMatches() {
    _matchIndices.clear();
    _currentMatchIndex = 0;
    if (_searchQuery.isEmpty) return;

    final state = _messageCubit.state;
    state.whenOrNull(
      loaded: (messages, localMessages, _) {
        final allMessages = [...messages, ...localMessages];
        allMessages.sort((a, b) {
          if (a.timestamp == null && b.timestamp == null) return 0;
          if (a.timestamp == null) return -1;
          if (b.timestamp == null) return 1;
          return b.timestamp!.compareTo(a.timestamp!);
        });
        for (int i = 0; i < allMessages.length; i++) {
          final m = allMessages[i];
          if (m.type == 'text' && m.text.toLowerCase().contains(_searchQuery)) {
            _matchIndices.add(i);
          }
        }
      },
    );
  }

  void _scrollToMatch() {
    if (_matchIndices.isEmpty) return;
    final state = _messageCubit.state;
    state.whenOrNull(
      loaded: (messages, localMessages, _) {
        final allMessages = [...messages, ...localMessages];
        allMessages.sort((a, b) {
          if (a.timestamp == null && b.timestamp == null) return 0;
          if (a.timestamp == null) return -1;
          if (b.timestamp == null) return 1;
          return b.timestamp!.compareTo(a.timestamp!);
        });
        final msg = allMessages[_matchIndices[_currentMatchIndex]];
        final key = _messageKeys[msg.id];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(key.currentContext!, alignment: 0.5, duration: const Duration(milliseconds: 300));
        }
      },
    );
  }

  bool _isTextNotEmpty = false;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  final _random = math.Random();
  List<double> _recordingWaves = List<double>.filled(26, 0.2);

  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _messageCubit = getIt<MessageCubit>();
    _messageCubit.loadMessages(widget.chatId, widget.currentUserId);
    _loadOtherUser();
    
    _toggleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _showAbout = !_showAbout;
        });
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
  }

  void _onTextChanged() {
    setState(() {
      _isTextNotEmpty = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _toggleTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();
    if (doc.exists && mounted) {
      final user = UserModel.fromJson({...doc.data()!, 'id': doc.id});
      setState(() {
        _otherUserName = user.name.isNotEmpty ? user.name : 'User';
        _otherUserAvatar = user.avatarUrl;
        _otherUserAbout = user.about;
        _isOtherUserOnline = user.isOnline;
        _otherUserLastSeen = user.lastSeen;
      });
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _messageCubit.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      text: text,
    );
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentMenu() {
    final colors = context.sawaColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          runSpacing: 24,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentIcon(Icons.insert_drive_file, Colors.indigo, 'Document', _pickDocument),
                _buildAttachmentIcon(Icons.camera_alt, Colors.pink, 'Camera', _pickCameraImage),
                _buildAttachmentIcon(Icons.insert_photo, Colors.purple, 'Gallery', _pickGalleryMedia),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentIcon(Icons.headset, Colors.orange, 'Audio', () {}), 
                _buildAttachmentIcon(Icons.location_on, Colors.green, 'Location', _sendLocation),
                _buildAttachmentIcon(Icons.person, Colors.blue, 'Contact', _pickContact),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon(IconData icon, Color color, String text, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); 
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: context.sawaColors.text1, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        _messageCubit.sendMediaMessage(
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          filePath: result.files.single.path!,
          type: 'file',
          metadata: {'fileName': result.files.single.name, 'size': result.files.single.size},
        );
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  /// Opens the [ImageEditPreviewScreen] with a picked file, then sends
  /// whatever the user decides (edited image or sticker).
  Future<void> _openEditPreview(File imageFile) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditPreviewScreen(
          imageFile: imageFile,
          chatId: widget.chatId,
          currentUserId: widget.currentUserId,
          otherUserName: _otherUserName,
          otherUserOnline: _isOtherUserOnline,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final file = result['file'] as File;
    final isSticker = result['isSticker'] as bool;

    _messageCubit.sendMediaMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      filePath: file.path,
      type: isSticker ? 'sticker' : 'image',
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerPicker(
        onStickerSelected: (path) {
          _messageCubit.sendMediaMessage(
            chatId: widget.chatId,
            senderId: widget.currentUserId,
            filePath: path,
            type: 'sticker',
          );
        },
      ),
    );
  }

  Future<void> _pickCameraImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        await _openEditPreview(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking camera image: $e');
    }
  }

  Future<void> _pickGalleryMedia() async {
    try {
      final picker = ImagePicker();
      final media = await picker.pickMedia();
      if (media != null) {
        final extension = media.name.split('.').last.toLowerCase();
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
        
        if (isVideo) {
          _messageCubit.sendMediaMessage(
            chatId: widget.chatId,
            senderId: widget.currentUserId,
            filePath: media.path,
            type: 'video',
          );
        } else if (mounted) {
          await _openEditPreview(File(media.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking gallery media: $e');
    }
  }

  Future<void> _sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationDialog(
          title: 'Enable Location',
          message: 'Location services are off. Please enable location to share your current position.',
          primaryLabel: 'Open Location Settings',
          onPrimaryTap: () async {
            await Geolocator.openLocationSettings();
          },
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showLocationDialog(
            title: 'Location Permission Needed',
            message: 'Please allow location permission to send your current location.',
            primaryLabel: 'Retry',
            onPrimaryTap: () async {
              await Geolocator.requestPermission();
            },
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        await _showLocationDialog(
          title: 'Permission Blocked',
          message: 'Location permission is permanently denied. Enable it from app settings.',
          primaryLabel: 'Open App Settings',
          onPrimaryTap: () async {
            await Geolocator.openAppSettings();
          },
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      
      _messageCubit.sendLocationMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        latitude: position.latitude,
        longitude: position.longitude,
        address:
            'Current Location (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})',
      );
    } catch (e) {
      debugPrint('Error fetching location: $e');
      await _showLocationDialog(
        title: 'Location Error',
        message: 'Failed to get current location. Please try again.',
        primaryLabel: 'OK',
        onPrimaryTap: () async {},
      );
    }
  }

  Future<void> _showLocationDialog({
    required String title,
    required String message,
    required String primaryLabel,
    required Future<void> Function() onPrimaryTap,
  }) async {
    if (!mounted) return;
    final colors = context.sawaColors;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: colors.text1,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: colors.text2,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.text3),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await onPrimaryTap();
            },
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _pickContact() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      final hasPermission =
          status == PermissionStatus.granted || status == PermissionStatus.limited;

      if (!hasPermission) {
        if (!mounted) return;
        final colors = context.sawaColors;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.card,
            title: Text(
              'Contacts Permission Needed',
              style: TextStyle(color: colors.text1),
            ),
            content: Text(
              'Please allow contacts access to share a contact card.',
              style: TextStyle(color: colors.text2),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colors.text3),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await FlutterContacts.permissions.openSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }

      final selectedId = await FlutterContacts.native.showPicker();
      if (selectedId == null || selectedId.isEmpty) return;

      final selected = await FlutterContacts.get(
        selectedId,
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (selected == null) return;

      final fullName = (selected.displayName ?? '').trim();
      final phone = selected.phones.isNotEmpty ? selected.phones.first.number.trim() : '';

      if (phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected contact has no phone number')),
        );
        return;
      }

      _messageCubit.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        text: fullName.isEmpty ? phone : fullName,
        type: 'contact',
        metadata: {
          'name': fullName.isEmpty ? 'Contact' : fullName,
          'phone': phone,
        },
      );
    } catch (e) {
      debugPrint('Error picking contact: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick contact')),
      );
    }
  }

  Future<void> _handleVoiceAction() async {
    if (_isTextNotEmpty) {
      _send();
    } else {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
          _recordingWaves = List<double>.filled(26, 0.2);
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
          });
        });

        Timer.periodic(const Duration(milliseconds: 140), (timer) {
          if (!_isRecording || !mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _recordingWaves = List.generate(
              26,
              (_) => 0.15 + (_random.nextDouble() * 0.85),
            );
          });
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _messageCubit.sendMediaMessage(
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          filePath: path,
          type: 'audio',
          metadata: {
            'duration': _recordingDuration,
          },
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser = authState.whenOrNull(authenticated: (u) => u);
        final isBlocked = currentUser?.blockedUsers.contains(widget.otherUserId) ?? false;
        
        return PopScope(
          canPop: !_showEmoji,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_showEmoji) {
              setState(() => _showEmoji = false);
            }
          },
          child: Scaffold(
            backgroundColor: colors.background,
            appBar: _buildAppBar(isBlocked),
            body: Column(
              children: [
                Expanded(child: _buildMessageList()),
                if (isBlocked)
                  _buildBlockedBanner(colors)
                else
                  _buildInputBar(),
                if (_showEmoji && !isBlocked) _buildEmojiPicker(colors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedBanner(SawaColors colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      color: colors.surface,
      child: Center(
        child: Text(
          'You blocked this contact. Tap their profile to unblock.',
          style: TextStyle(color: colors.text2, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker(SawaColors colors) {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        textEditingController: _controller,
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: colors.card,
            columns: 7,
            emojiSizeMax: 28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
          ),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: colors.card,
            dividerColor: colors.divider,
            indicatorColor: AppColors.primary,
            iconColorSelected: AppColors.primary,
            iconColor: colors.text3,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            backgroundColor: colors.card,
            buttonColor: colors.card,
            buttonIconColor: colors.text3,
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: colors.card,
            hintText: 'Search emoji...',
            buttonIconColor: colors.text1,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isBlocked) {
    if (_isSearching) {
      return AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
              _matchIndices.clear();
            });
          },
        ),
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
                _updateSearchMatches();
                if (_matchIndices.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMatch());
                }
              });
            },
          ),
        ),
        actions: [
          if (_matchIndices.isNotEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '${_currentMatchIndex + 1} of ${_matchIndices.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
              onPressed: () {
                if (_currentMatchIndex < _matchIndices.length - 1) {
                  setState(() => _currentMatchIndex++);
                  _scrollToMatch();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onPressed: () {
                if (_currentMatchIndex > 0) {
                  setState(() => _currentMatchIndex--);
                  _scrollToMatch();
                }
              },
            ),
          ] else if (_searchQuery.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _matchIndices.clear();
                });
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContactProfileScreen(
                userId: widget.otherUserId,
                chatId: widget.chatId,
              ),
            ),
          ).then((startSearch) {
            if (startSearch == true) {
              setState(() => _isSearching = true);
            }
          });
        },
        child: Row(
          children: [
          BlocBuilder<StoryCubit, StoryState>(
            builder: (context, storyState) {
              List<StoryModel> userStories = [];
              storyState.whenOrNull(
                loaded: (stories, _, _) {
                  userStories = stories.where((s) => s.userId == widget.otherUserId).toList();
                },
              );
              return StoryRingAvatar(
                avatarUrl: _otherUserAvatar,
                userName: _otherUserName,
                stories: userStories,
                currentUserId: widget.currentUserId,
                radius: 20,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _otherUserName.isNotEmpty ? _otherUserName : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildSubtitle(isBlocked),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.accent),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppColors.accent),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppColors.accent),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool isBlocked) {
    if (isBlocked) {
      return const SizedBox.shrink(key: ValueKey('empty'));
    }

    if (_showAbout && _otherUserAbout.isNotEmpty) {
      return Text(
        _otherUserAbout,
        key: const ValueKey('about'),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        overflow: TextOverflow.ellipsis,
      );
    }

    if (_isOtherUserOnline) {
      return Text(
        'Online',
        key: const ValueKey('online'),
        style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      );
    }

    if (_otherUserLastSeen != null) {
      return Text(
        'Last seen ${_formatLastSeen(_otherUserLastSeen!)}',
        key: const ValueKey('last_seen'),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
        overflow: TextOverflow.ellipsis,
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    if (dateToCheck == today) {
      return 'today at ${DateFormat('jm').format(lastSeen)}';
    } else if (dateToCheck == yesterday) {
      return 'yesterday at ${DateFormat('jm').format(lastSeen)}';
    } else {
      return DateFormat('MMM d, yyyy').format(lastSeen);
    }
  }

  Widget _buildMessageList() {
    return BlocBuilder<MessageCubit, MessageState>(
      bloc: _messageCubit,
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          loaded: (messages, localMessages, uploadProgress) {
            var allMessages = [...messages, ...localMessages];

            // Sort newest first for reverse list
            allMessages.sort((a, b) {
              if (a.timestamp == null && b.timestamp == null) return 0;
              if (a.timestamp == null) return -1; // Local/unsent messages at the bottom
              if (b.timestamp == null) return 1;
              return b.timestamp!.compareTo(a.timestamp!);
            });

            if (allMessages.isEmpty) {
              return const Center(
                child: SawaEmptyState(
                  icon: Icons.mark_chat_unread_outlined,
                  title: 'Say hello! 👋',
                  subtitle: 'Send your first message to start the conversation',
                ),
              );
            }

            if (_isSearching) {
              return SingleChildScrollView(
                reverse: true, // New messages appear at the bottom
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allMessages.reversed.map((msg) {
                    final isHighlighted = _searchQuery.isNotEmpty && 
                                          _matchIndices.isNotEmpty && 
                                          allMessages[_matchIndices[_currentMatchIndex]].id == msg.id;
                    return MessageBubble(
                      key: _getKey(msg.id),
                      message: msg,
                      isSent: msg.senderId == widget.currentUserId,
                      uploadProgress: uploadProgress[msg.id],
                      searchQuery: _searchQuery,
                      isHighlighted: isHighlighted,
                    );
                  }).toList(),
                ),
              );
            }

            return ListView.builder(
              reverse: true, // New messages appear at the bottom (index 0)
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: allMessages.length,
              itemBuilder: (context, index) {
                final msg = allMessages[index];
                return MessageBubble(
                  message: msg,
                  isSent: msg.senderId == widget.currentUserId,
                  uploadProgress: uploadProgress[msg.id],
                );
              },
            );
          },
          error: (msg) => Center(
            child: Text(msg, style: const TextStyle(color: AppColors.missed)),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final colors = context.sawaColors;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _isRecording
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.input,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          height: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _recordingWaves.map((level) {
                              return Container(
                                width: 3,
                                height: 6 + (level * 12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Text('Tap mic to stop', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                      ],
                    ),
                  )
                : TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: colors.text1, fontSize: 15),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.input,
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: colors.text3.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                              color: colors.text2,
                              size: 22,
                            ),
                            onPressed: () {
                              if (_showEmoji) {
                                _focusNode.requestFocus();
                              } else {
                                _focusNode.unfocus();
                              }
                              setState(() => _showEmoji = !_showEmoji);
                            },
                            tooltip: 'الرموز التعبيرية',
                          ),
                          IconButton(
                            icon: Icon(Icons.auto_awesome_rounded, color: colors.text2, size: 22),
                            onPressed: _showStickerPicker,
                            tooltip: 'الملصقات',
                          ),
                        ],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.attach_file, color: colors.text2),
                        onPressed: _showAttachmentMenu,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colors.divider, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.0),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isTextNotEmpty ? Icons.send_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _handleVoiceAction,
            ),
          ),
        ],
      ),
    );
  }
}
