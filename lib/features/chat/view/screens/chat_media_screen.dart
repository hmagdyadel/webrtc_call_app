import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/sawa_empty_state.dart';
import '../../data/models/message_model.dart';
import 'image_preview_screen.dart'; // To preview images

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class ChatMediaScreen extends StatelessWidget {
  final String chatId;

  const ChatMediaScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Media, Links, and Docs', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Media'),
              Tab(text: 'Links'),
              Tab(text: 'Docs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MediaTab(chatId: chatId),
            _LinksTab(chatId: chatId),
            _DocsTab(chatId: chatId),
          ],
        ),
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  final String chatId;

  const _MediaTab({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('type', whereIn: ['image', 'video'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: SawaEmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No media',
              subtitle: 'Images and videos shared in this chat will appear here.',
            ),
          );
        }

        final messages = snapshot.data!.docs.map((d) => MessageModel.fromJson({...d.data() as Map<String, dynamic>, 'id': d.id})).toList();
        messages.sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return GestureDetector(
              onTap: () {
                if (msg.type == 'image' && msg.mediaUrl != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImagePreviewScreen(imagePath: msg.mediaUrl!),
                    ),
                  );
                }
              },
              child: Image.network(
                msg.mediaUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: colors.card, child: const Icon(Icons.broken_image, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
}

class _LinksTab extends StatelessWidget {
  final String chatId;

  const _LinksTab({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    // Links require querying all text messages and filtering locally since Firestore cannot search substrings
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('type', isEqualTo: 'text')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData) return const SizedBox.shrink();

        final messages = snapshot.data!.docs
            .map((d) => MessageModel.fromJson({...d.data() as Map<String, dynamic>, 'id': d.id}))
            .where((m) => m.text.contains('http://') || m.text.contains('https://'))
            .toList();
        
        messages.sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));

        if (messages.isEmpty) {
          return const Center(
            child: SawaEmptyState(
              icon: Icons.link,
              title: 'No links',
              subtitle: 'Links shared in this chat will appear here.',
            ),
          );
        }

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return ListTile(
              leading: CircleAvatar(backgroundColor: colors.card, child: const Icon(Icons.link, color: AppColors.primary)),
              title: Text(msg.text, style: TextStyle(color: colors.text1), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: msg.timestamp != null ? Text(msg.timestamp.toString(), style: TextStyle(color: colors.text3, fontSize: 12)) : null,
              onTap: () {
                // Could launch URL here using url_launcher
              },
            );
          },
        );
      },
    );
  }
}

class _DocsTab extends StatelessWidget {
  final String chatId;

  const _DocsTab({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('type', isEqualTo: 'file')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: SawaEmptyState(
              icon: Icons.insert_drive_file_outlined,
              title: 'No documents',
              subtitle: 'Documents shared in this chat will appear here.',
            ),
          );
        }

        final messages = snapshot.data!.docs.map((d) => MessageModel.fromJson({...d.data() as Map<String, dynamic>, 'id': d.id})).toList();
        messages.sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final fileName = msg.metadata?['name']?.toString() ?? 'Unknown file';
            final rawSize = msg.metadata?['size'];
            final fileSize = rawSize is int ? _formatBytes(rawSize) : (rawSize?.toString() ?? '0 B');

            return ListTile(
              leading: CircleAvatar(backgroundColor: colors.card, child: const Icon(Icons.insert_drive_file, color: AppColors.primary)),
              title: Text(fileName, style: TextStyle(color: colors.text1)),
              subtitle: Text(fileSize, style: TextStyle(color: colors.text3)),
              onTap: () {
                // Could open file here
              },
            );
          },
        );
      },
    );
  }
}
