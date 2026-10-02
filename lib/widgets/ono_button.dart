import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A premium animated button with gradient background, press animation,
/// and clear disabled state.
class OnoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool fullWidth;
  final IconData? icon;
  final bool isLoading;

  const OnoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.fullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<OnoButton> createState() => _OnoButtonState();
}

class _OnoButtonState extends State<OnoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_isEnabled) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _scaleController.reverse();
      HapticFeedback.mediumImpact();
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isEnabled ? 1.0 : 0.45,
          child: SizedBox(
            width: widget.fullWidth ? double.infinity : null,
            height: 58,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: widget.isSecondary ? AppColors.card : AppColors.accent,
                border: widget.isSecondary
                    ? Border.all(color: AppColors.divider, width: 1)
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.ink,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: widget.isSecondary
                                  ? AppColors.white
                                  : AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.icon != null) ...[
                            const SizedBox(width: 10),
                            Icon(widget.icon,
                                size: 20,
                                color: widget.isSecondary
                                    ? AppColors.white
                                    : AppColors.ink),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnoTag extends StatelessWidget {
  final String label;
  const OnoTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purpleDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.purple,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
