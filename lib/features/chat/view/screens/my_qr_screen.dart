import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';

class MyQRScreen extends StatelessWidget {
  const MyQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;
    final authState = context.read<AuthCubit>().state;
    String? currentUserId;
    String? currentUserName;
    String? currentUserPhone;

    authState.maybeWhen(
      authenticated: (user) {
        currentUserId = user.id;
        currentUserName = user.name.isNotEmpty ? user.name : null;
        currentUserPhone = user.phone;
      },
      orElse: () {},
    );

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('User not found'),
        ),
        body: Center(
          child: Text('User not found', style: TextStyle(color: colors.text3)),
        ),
      );
    }

    final displayName = currentUserName ?? currentUserPhone ?? 'User';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My QR Code'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: currentUserId!,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppColors.darkBg, // Always dark on white card
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentUserName != null && currentUserPhone != null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Scan to connect',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Scan this code to start a chat\nامسح هذا الرمز لبدء محادثة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text3,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
