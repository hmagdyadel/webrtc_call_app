import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';

class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String displayName = 'My Profile';
        String? avatarUrl;
        state.whenOrNull(authenticated: (user) {
          displayName = user.name.isNotEmpty ? user.name : user.phone;
          avatarUrl = user.avatarUrl.isNotEmpty ? user.avatarUrl : null;
        });

        return Scaffold(
          backgroundColor: colors.surface, // Standard settings background
          appBar: AppBar(
            title: const Text('Settings'),
            elevation: 0,
            backgroundColor: colors.surface,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                InkWell(
                  onTap: () => context.push(AppRoutePaths.profile),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primary,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                            child: avatarUrl == null 
                                ? const Icon(Icons.person, color: Colors.white, size: 36) 
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(color: colors.text1, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hey there! I am using Sawa.',
                                style: TextStyle(color: colors.text2, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.qr_code, color: AppColors.primary),
                              onPressed: () => context.push(AppRoutePaths.myQr),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                
                Divider(color: colors.divider, thickness: 8),
                
                // Settings Groups
                _buildSettingsTile(
                  context,
                  title: 'Account',
                  subtitle: 'Security notifications, change number',
                  icon: Icons.key_outlined,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  title: 'Privacy',
                  subtitle: 'Block contacts, disappearing messages',
                  icon: Icons.lock_outline,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                ),
                _buildSettingsTile(
                  context,
                  title: 'Chats',
                  subtitle: 'Theme, wallpapers, chat history',
                  icon: Icons.chat_outlined,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  title: 'Notifications',
                  subtitle: 'Message, group & call tones',
                  icon: Icons.notifications_none,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  title: 'Storage and data',
                  subtitle: 'Network usage, auto-download',
                  icon: Icons.data_usage,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  title: 'App language',
                  subtitle: 'English (device\'s language)',
                  icon: Icons.language,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  title: 'Help',
                  subtitle: 'Help center, contact us, privacy policy',
                  icon: Icons.help_outline,
                  onTap: () {},
                ),

                Divider(color: colors.divider, thickness: 8),

                _buildSettingsTile(
                  context,
                  title: 'Invite a friend',
                  icon: Icons.people_outline,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context,
                  title: 'Sign Out',
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  onTap: () => _showSignOut(context),
                ),
                
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'from\nMETA', // WhatsApp style branding
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.text3, fontSize: 12, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final colors = context.sawaColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? colors.text2, size: 24),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? colors.text1,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.text2, fontSize: 13),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOut(BuildContext context) {
    final colors = context.sawaColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Sign Out', style: TextStyle(color: colors.text1)),
        content: Text('Are you sure you want to sign out?', style: TextStyle(color: colors.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppColors.primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Temporary placeholder for PrivacyScreen to avoid errors until we create it.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: const Center(child: Text('Privacy Settings')),
    );
  }
}
