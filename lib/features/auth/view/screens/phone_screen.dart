import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../viewmodel/auth_cubit.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = '+20';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    EasyLoading.show(status: 'Sending OTP...');

    final fullPhone = '$_countryCode$phone';
    final cubit = context.read<AuthCubit>();

    await cubit.sendOTPWithCallback(
      phoneNumber: fullPhone,
      onCodeSent: () {
        EasyLoading.dismiss();
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.push(AppRoutePaths.otp, extra: fullPhone);
      },
      onError: (error) {
        EasyLoading.dismiss();
        EasyLoading.showError(error);
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sawaColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        title: Text(
          'Enter your phone',
          style: TextStyle(color: colors.text1),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Your phone number',
              style: TextStyle(
                color: colors.text1,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will send you a verification code',
              style: TextStyle(color: colors.text3, fontSize: 14),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: colors.input,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: colors.divider, width: 0.5),
                        ),
                      ),
                      child: Text(
                        _countryCode,
                        style: TextStyle(
                          color: colors.text1,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: colors.text1),
                      decoration: InputDecoration(
                        hintText: '10 digit number',
                        hintStyle: TextStyle(color: colors.text3),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    final colors = context.sawaColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      builder: (_) => ListView(
        children: [
          _countryTile('Egypt', '+20'),
          _countryTile('Saudi Arabia', '+966'),
          _countryTile('UAE', '+971'),
          _countryTile('USA', '+1'),
          _countryTile('UK', '+44'),
        ],
      ),
    );
  }

  Widget _countryTile(String name, String code) {
    final colors = context.sawaColors;
    return ListTile(
      title: Text(name, style: TextStyle(color: colors.text1)),
      trailing: Text(code, style: TextStyle(color: colors.text3)),
      onTap: () {
        setState(() => _countryCode = code);
        context.pop();
      },
    );
  }
}