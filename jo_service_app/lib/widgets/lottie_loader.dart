import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/theme.dart';

class LottieLoader extends StatelessWidget {
  final String type; // 'loading', 'success', 'error', 'empty', or custom
  final String? assetPath;
  final String? message;
  final bool fullScreen;
  final double size;
  final bool animate;
  final bool loop;
  final double speed;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onAnimationComplete;

  const LottieLoader({
    Key? key,
    this.type = 'loading',
    this.assetPath,
    this.message,
    this.fullScreen = false,
    this.size = 150,
    this.animate = true,
    this.loop = true,
    this.speed = 1,
    this.padding,
    this.backgroundColor,
    this.onAnimationComplete,
  }) : super(key: key);

  // Get the appropriate Lottie animation asset path
  String _getAnimationPath() {
    if (assetPath != null) {
      return assetPath!;
    }

    switch (type) {
      case 'success':
        return 'assets/animations/success.json';
      case 'error':
        return 'assets/animations/error.json';
      case 'empty':
        return 'assets/animations/empty.json';
      case 'loading':
      default:
        return 'assets/animations/loading.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationPath = _getAnimationPath();
    final containerPadding = padding ?? const EdgeInsets.all(20);

    // For full screen loader
    if (fullScreen) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: backgroundColor ?? AppTheme.white,
        child: Center(
          child: _buildContent(animationPath, containerPadding),
        ),
      );
    }

    // For inline loader
    return Container(
      padding: containerPadding,
      alignment: Alignment.center,
      child: _buildContent(animationPath, EdgeInsets.zero),
    );
  }

  Widget _buildContent(String animationPath, EdgeInsetsGeometry padding) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimation(animationPath),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: AppTheme.h4.copyWith(color: AppTheme.dark),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimation(String animationPath) {
    try {
      return Lottie.asset(
        animationPath,
        width: size,
        height: size,
        animate: animate,
        repeat: loop,
        onLoaded: (composition) {
          if (onAnimationComplete != null && !loop) {
            Future.delayed(composition.duration, onAnimationComplete);
          }
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Lottie Error: $error');
          return _buildFallbackLoader();
        },
      );
    } catch (e) {
      debugPrint('Failed to load Lottie animation: $e');
      return _buildFallbackLoader();
    }
  }

  Widget _buildFallbackLoader() {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 4,
        ),
      ),
    );
  }
}
