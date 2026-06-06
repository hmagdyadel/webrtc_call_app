import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/viewmodel/auth_cubit.dart';
import '../../../auth/viewmodel/auth_state.dart';
import '../../viewmodel/story_cubit.dart';

/// Full-screen text story composer with background color picker and font toggle.
class TextStoryEditor extends StatefulWidget {
  final String userId;
  const TextStoryEditor({super.key, required this.userId});

  @override
  State<TextStoryEditor> createState() => _TextStoryEditorState();
}

class _TextStoryEditorState extends State<TextStoryEditor> {
  final _controller = TextEditingController();
  int _selectedColorIndex = 0;
  int _selectedFontIndex = 0;

  static const List<List<Color>> _gradients = [
    [Color(0xFF5B4FD4), Color(0xFF7B6FEE)], // Purple (Sawa brand)
    [Color(0xFF00C8A0), Color(0xFF00E5BF)], // Teal
    [Color(0xFFFF6B6B), Color(0xFFFF8E8E)], // Coral
    [Color(0xFF667EEA), Color(0xFF764BA2)], // Indigo → Purple
    [Color(0xFFFFAB40), Color(0xFFFF6E40)], // Orange → Red
    [Color(0xFF0D0D1E), Color(0xFF1A1A3E)], // Dark
    [Color(0xFFF093FB), Color(0xFFF5576C)], // Pink
    [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Sky Blue
  ];

  static const List<String> _fontFamilies = [
    'Plus Jakarta Sans',
    'Playfair Display',
    'Space Mono',
    'Dancing Script',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _getTextStyle() {
    final fontFamily = _fontFamilies[_selectedFontIndex];
    switch (fontFamily) {
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        );
      case 'Space Mono':
        return GoogleFonts.spaceMono(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        );
      case 'Dancing Script':
        return GoogleFonts.dancingScript(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        );
      default:
        return GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[_selectedColorIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    // Font toggle
                    _PillButton(
                      icon: Icons.text_format,
                      label: 'Font',
                      onTap: () {
                        setState(() {
                          _selectedFontIndex =
                              (_selectedFontIndex + 1) % _fontFamilies.length;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ── Text input area ──────────────────────────────
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      maxLines: null,
                      style: _getTextStyle(),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Type a status...',
                        hintStyle: _getTextStyle().copyWith(
                          color: Colors.white38,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Color picker ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _gradients.length,
                    (index) => GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _gradients[index],
                          ),
                          border: Border.all(
                            color: _selectedColorIndex == index
                                ? Colors.white
                                : Colors.white24,
                            width: _selectedColorIndex == index ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Send button ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('نشر الحالة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Transform.flip(
                            flipX: true,
                            child: const Icon(Icons.send_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    authState.whenOrNull(authenticated: (user) {
      final gradient = _gradients[_selectedColorIndex];
      // Store the first color as hex string
      final bgColor = '#${gradient[0].toARGB32().toRadixString(16).padLeft(8, '0')}';

      context.read<StoryCubit>().uploadTextStory(
            userId: widget.userId,
            userName: user.name,
            userAvatar: user.avatarUrl,
            text: text,
            backgroundColor: bgColor,
            fontFamily: _fontFamilies[_selectedFontIndex],
          );

      Navigator.pop(context);
    });
  }
}

// ── Pill Button ────────────────────────────────────────────────────────
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
