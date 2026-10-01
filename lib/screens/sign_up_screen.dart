import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/ono_button.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _emailController.text.contains('@') &&
        _passwordController.text.length >= 6 &&
        _passwordController.text == _confirmController.text;
  }

  int get _passwordStrength {
    final pw = _passwordController.text;
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 6) score++;
    if (pw.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Very strong';
    }
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 0:
        return Colors.transparent;
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.cyan;
      case 4:
      default:
        return AppColors.green;
    }
  }

  Future<void> _handleSignUp() async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted && auth.isAuthenticated) {
      context.go('/archetype');
    }
  }

  Future<void> _handleAppleSignIn() async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    await auth.signInWithApple();
    if (mounted && auth.isAuthenticated) {
      context.go('/home');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
    if (mounted && auth.isAuthenticated) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0A1E),
              Color(0xFF0A0C14),
              Color(0xFF0A1014),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow orb
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/welcome');
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.divider.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: AppColors.grey, size: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'ONO',
                          style: TextStyle(
                            color: AppColors.purpleSoft,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create your\naccount',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start your transformation journey',
                          style: TextStyle(color: AppColors.grey, fontSize: 15),
                        ),

                        // -- Social sign-in buttons -----------------------
                        const SizedBox(height: 28),
                        if (!kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.iOS) ...[
                          _SocialButton(
                            label: 'Continue with Apple',
                            icon: Icons.apple,
                            onTap: isLoading ? null : _handleAppleSignIn,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _SocialButton(
                          label: 'Continue with Google',
                          iconWidget: _googleIcon(),
                          onTap: isLoading ? null : _handleGoogleSignIn,
                        ),

                        // -- Divider --------------------------------------
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.divider.withValues(alpha: 0.5),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or sign up with email',
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.divider.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // -- Email field ----------------------------------
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'your@email.com',
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.mail_outline_rounded,
                          autofillHints: const [
                            AutofillHints.email,
                            AutofillHints.username,
                          ],
                        ),
                        const SizedBox(height: 16),

                        // -- Password field with strength indicator -------
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Min 6 characters',
                          obscure: _obscurePassword,
                          icon: Icons.lock_outline_rounded,
                          autofillHints: const [AutofillHints.newPassword],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (i) {
                              return Expanded(
                                child: Container(
                                  height: 3,
                                  margin: EdgeInsets.only(
                                    right: i < 4 ? 6 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: i < _passwordStrength
                                        ? _strengthColor
                                        : AppColors.divider
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _strengthLabel,
                              style: TextStyle(
                                color: _strengthColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // -- Confirm password field -----------------------
                        _buildTextField(
                          controller: _confirmController,
                          label: 'Confirm password',
                          hint: 'Repeat your password',
                          obscure: _obscureConfirm,
                          icon: Icons.lock_outline_rounded,
                          autofillHints: const [AutofillHints.newPassword],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // -- Error message --------------------------------
                        if (auth.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.8),
                                    size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: TextStyle(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                        OnoButton(
                          label: 'Create account',
                          isLoading: isLoading,
                          onPressed:
                              isLoading || !_isValid ? null : _handleSignUp,
                          icon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/sign-in'),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 14),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      color: AppColors.purpleSoft,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    List<String> autofillHints = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.greyLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscure,
                autofillHints: autofillHints,
                style: const TextStyle(color: AppColors.white, fontSize: 15),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.grey),
                  prefixIcon: Icon(icon, color: AppColors.grey, size: 20),
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

// -- Social sign-in button ------------------------------------------------

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    this.icon,
    this.iconWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null)
                  iconWidget!
                else if (icon != null)
                  Icon(icon, color: AppColors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Google logo painter (no external asset needed) -----------------------

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -0.5,
      1.9,
      true,
      bluePaint,
    );

    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      1.4,
      1.1,
      true,
      greenPaint,
    );

    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      2.5,
      1.1,
      true,
      yellowPaint,
    );

    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      3.6,
      1.3,
      true,
      redPaint,
    );

    // White center
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.3,
      whitePaint,
    );

    // Blue bar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.35, w * 0.5, h * 0.3),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
