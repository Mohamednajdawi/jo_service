import 'package:flutter/material.dart';
import '../constants/theme.dart';

class AnimatedCard extends StatefulWidget {
  final String? title;
  final String? description;
  final Widget? image;
  final VoidCallback? onPressed;
  final Widget? icon;
  final List<Widget>? children;
  final String variant; // 'default', 'outline', 'minimal'
  final bool animated;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final Duration animationDuration;
  final int animationDelay;

  const AnimatedCard({
    Key? key,
    this.title,
    this.description,
    this.image,
    this.onPressed,
    this.icon,
    this.children,
    this.variant = 'default',
    this.animated = true,
    this.padding,
    this.decoration,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationDelay = 0,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.animated ? 0.8 : 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: widget.animated ? 0.0 : 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.animated ? const Offset(0, 0.2) : Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    if (widget.animated) {
      Future.delayed(Duration(milliseconds: widget.animationDelay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get card decoration based on variant
  BoxDecoration _getCardDecoration() {
    switch (widget.variant) {
      case 'outline':
        return BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.greyLight),
        );
      case 'minimal':
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        );
      case 'default':
      default:
        return BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [AppTheme.mediumShadow],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ?? _getCardDecoration();
    final padding = widget.padding ?? const EdgeInsets.all(AppTheme.padding);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width:
                    MediaQuery.of(context).size.width - (AppTheme.padding * 2),
                margin: const EdgeInsets.only(bottom: AppTheme.padding),
                decoration: decoration,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.image != null) _buildPulsingImage(),
                          if (widget.icon != null)
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTheme.baseSize),
                                child: widget.icon,
                              ),
                            ),
                          if (widget.title != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppTheme.baseSize),
                              child: Text(
                                widget.title!,
                                style:
                                    AppTheme.h3.copyWith(color: AppTheme.dark),
                              ),
                            ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              style:
                                  AppTheme.body4.copyWith(color: AppTheme.grey),
                            ),
                          if (widget.children != null) ...widget.children!,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulsingImage() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.baseSize),
            child: Align(
              alignment: Alignment.center,
              child: widget.image,
            ),
          ),
        );
      },
      child: widget.image,
    );
  }
}
