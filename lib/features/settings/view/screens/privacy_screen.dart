import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import 'blocked_contacts_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Who can see my personal info',
                style: TextStyle(color: colors.text2, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            _buildPrivacyOption(context, 'Last seen and online', 'Everyone'),
            _buildPrivacyOption(context, 'Profile photo', 'Everyone'),
            _buildPrivacyOption(context, 'About', 'Everyone'),
            _buildPrivacyOption(context, 'Status', 'My contacts'),
            
            Divider(color: colors.divider, thickness: 8),

            _buildPrivacyOption(
              context, 
              'Read receipts', 
              null,
              hasSwitch: true,
              switchValue: true,
              subtitle: 'If turned off, you won\'t send or receive Read receipts. Read receipts are always sent for group chats.',
            ),

            Divider(color: colors.divider, thickness: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Disappearing messages',
                style: TextStyle(color: colors.text2, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            _buildPrivacyOption(
              context, 
              'Default message timer', 
              'Off',
              subtitle: 'Start new chats with disappearing messages set to your timer.',
            ),

            Divider(color: colors.divider, thickness: 8),
            
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                int blockedCount = 0;
                state.whenOrNull(authenticated: (user) {
                  blockedCount = user.blockedUsers.length;
                });
                return _buildPrivacyOption(
                  context, 
                  'Blocked contacts', 
                  blockedCount == 0 ? 'None' : blockedCount.toString(),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedContactsScreen()));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context, 
    String title, 
    String? value, {
    bool hasSwitch = false,
    bool switchValue = false,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final colors = context.sawaColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: colors.text1, fontSize: 16)),
                if (value != null)
                  Text(value, style: TextStyle(color: colors.text2, fontSize: 16)),
                if (hasSwitch)
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: switchValue,
                      onChanged: (v) {},
                      activeTrackColor: AppColors.primary.withAlpha(128),
                      activeThumbColor: AppColors.primary,
                    ),
                  )
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: colors.text2, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
