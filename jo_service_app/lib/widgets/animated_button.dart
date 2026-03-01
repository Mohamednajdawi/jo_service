import 'package:flutter/material.dart';
import '../constants/theme.dart';

class AnimatedButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final String variant; // 'filled', 'outlined'
  final String size; // 'small', 'medium', 'large'
  final bool disabled;
  final bool fullWidth;
  final Widget? icon;

  const AnimatedButton({
    Key? key,
    required this.title,
    this.onPressed,
    this.style,
    this.textStyle,
    this.variant = 'filled',
    this.size = 'medium',
    this.disabled = false,
    this.fullWidth = false,
    this.icon,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get padding based on button size
  EdgeInsetsGeometry _getSizePadding() {
    switch (widget.size) {
      case 'small':
        return const EdgeInsets.symmetric(vertical: 8, horizontal: 16);
      case 'large':
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 32);
      case 'medium':
      default:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 24);
    }
  }

  // Get border radius based on button size
  BorderRadius _getSizeBorderRadius() {
    switch (widget.size) {
      case 'small':
        return BorderRadius.circular(8);
      case 'large':
        return BorderRadius.circular(12);
      case 'medium':
      default:
        return BorderRadius.circular(10);
    }
  }

  // Get button style based on variant
  ButtonStyle _getButtonStyle() {
    final basePadding = _getSizePadding();
    final borderRadius = _getSizeBorderRadius();

    switch (widget.variant) {
      case 'outlined':
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: widget.disabled ? AppTheme.grey : AppTheme.primary,
          elevation: 0,
          padding: basePadding,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color: widget.disabled ? AppTheme.greyLight : AppTheme.primary,
              width: 2,
            ),
          ),
          disabledForegroundColor: AppTheme.grey.withOpacity(0.6),
          disabledBackgroundColor: Colors.transparent,
        );
      case 'filled':
      default:
        return ElevatedButton.styleFrom(
          backgroundColor:
              widget.disabled ? AppTheme.greyLight : AppTheme.primary,
          foregroundColor: AppTheme.white,
          elevation: 4,
          shadowColor: AppTheme.black.withOpacity(0.2),
          padding: basePadding,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          disabledForegroundColor: AppTheme.white.withOpacity(0.6),
          disabledBackgroundColor: AppTheme.greyLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.disabled ? null : _controller.forward(),
      onTapUp: (_) => widget.disabled ? null : _controller.reverse(),
      onTapCancel: () => widget.disabled ? null : _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.fullWidth ? double.infinity : null,
              child: ElevatedButton(
                onPressed: widget.disabled ? null : widget.onPressed,
                style: widget.style ?? _getButtonStyle(),
                child: Row(
                  mainAxisSize:
                      widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.title,
                      style: widget.textStyle ??
                          AppTheme.h4.copyWith(
                            color: _getTextColor(),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTextColor() {
    if (widget.disabled) {
      return widget.variant == 'outlined'
          ? AppTheme.grey
          : AppTheme.white.withOpacity(0.6);
    } else {
      return widget.variant == 'outlined' ? AppTheme.primary : AppTheme.white;
    }
  }
}
