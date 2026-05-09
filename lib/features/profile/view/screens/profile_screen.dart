import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    final authState = context.watch<AuthCubit>().state;

    String name = 'اسمك هنا';
    String phone = '';
    String? avatarUrl;

    authState.maybeWhen(
      authenticated: (user) {
        name = user.name.isNotEmpty ? user.name : 'بدون اسم';
        phone = user.phone;
        avatarUrl = user.avatarUrl;
      },
      orElse: () {},
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ── User info section ──────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.divider,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0] : 'أ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.text1,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(
                          color: colors.text2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),

          // ── Appearance section ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              'المظهر',
              style: TextStyle(
                color: colors.text3,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.divider,
                width: 0.5,
              ),
            ),
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return Column(
                  children: [
                    _ThemeOption(
                      icon: Icons.brightness_auto_outlined,
                      label: 'حسب الجهاز',
                      sublabel: 'System default',
                      isSelected: themeMode == ThemeMode.system,
                      onTap: () => getIt<ThemeCubit>().setSystem(),
                      showDivider: true,
                    ),
                    _ThemeOption(
                      icon: Icons.dark_mode_outlined,
                      label: 'الوضع الليلي',
                      sublabel: 'Dark mode',
                      isSelected: themeMode == ThemeMode.dark,
                      onTap: () => getIt<ThemeCubit>().setDark(),
                      showDivider: true,
                    ),
                    _ThemeOption(
                      icon: Icons.light_mode_outlined,
                      label: 'الوضع النهاري',
                      sublabel: 'Light mode',
                      isSelected: themeMode == ThemeMode.light,
                      onTap: () => getIt<ThemeCubit>().setLight(),
                      showDivider: false,
                    ),
                  ],
                );
              },
            ),
          ),

          // ── QR Code ───────────────────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'الاتصال',
              style: TextStyle(
                color: colors.text3,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.divider,
                width: 0.5,
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code, color: AppColors.primary, size: 20),
              ),
              title: const Text('رمز QR الخاص بي'),
              subtitle: const Text('شارك رمزك لبدء محادثة فورية'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {},
            ),
          ),

          // ── Sign out ──────────────────────────────────
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              tileColor: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colors.divider,
                  width: 0.5,
                ),
              ),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.missed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout, color: AppColors.missed, size: 20),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: AppColors.missed),
              ),
              onTap: () {
                context.read<AuthCubit>().signOut();
              },
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : colors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : colors.text2,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : colors.text1,
            ),
          ),
          subtitle: Text(
            sublabel,
            style: TextStyle(
              fontSize: 12,
              color: colors.text3,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
              : Icon(
                  Icons.circle_outlined,
                  size: 22,
                  color: colors.text3,
                ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: 64,
            thickness: 0.5,
            color: colors.divider,
          ),
      ],
    );
  }
}
