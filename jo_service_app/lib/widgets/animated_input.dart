import 'package:flutter/material.dart';
import '../constants/theme.dart';

class AnimatedInput extends StatefulWidget {
  final String? label;
  final String? value;
  final Function(String)? onChanged;
  final String? placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? error;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? icon;
  final String iconPosition; // 'left', 'right'
  final bool disabled;
  final bool multiline;
  final int? maxLength;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  const AnimatedInput({
    Key? key,
    this.label,
    this.value,
    this.onChanged,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.error,
    this.contentPadding,
    this.icon,
    this.iconPosition = 'right',
    this.disabled = false,
    this.multiline = false,
    this.maxLength,
    this.readOnly = false,
    this.minLines,
    this.maxLines,
    this.textStyle,
    this.decoration,
    this.focusNode,
    this.controller,
  }) : super(key: key);

  @override
  State<AnimatedInput> createState() => _AnimatedInputState();
}

class _AnimatedInputState extends State<AnimatedInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;

  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isPasswordVisible = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: 18.0,
      end: -8.0, // Changed from 0.0 to -8.0 to move label above the border
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _sizeAnimation = Tween<double>(
      begin: 16.0,
      end: 12.0, // Slightly smaller for better visibility
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: AppTheme.grey,
      end: AppTheme.primary,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Set initial animation state based on whether there's text
    if (_controller.text.isNotEmpty) {
      _animationController.value = 1.0;
    }

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChange);
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else if (_controller.text.isEmpty) {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }

    if (_controller.text.isNotEmpty && _animationController.value == 0) {
      _animationController.forward();
    } else if (_controller.text.isEmpty && !_focusNode.hasFocus) {
      _animationController.reverse();
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.error != null
        ? AppTheme.danger
        : _isFocused
            ? AppTheme.primary
            : AppTheme.greyLight;

    final Color backgroundColor =
        widget.disabled ? AppTheme.greyLight : AppTheme.white;

    final EdgeInsetsGeometry padding = widget.contentPadding ??
        EdgeInsets.only(
          left: 15,
          right: 15,
          top: 20, // Reduced from 24 to account for new margin
          bottom: widget.multiline ? 12 : 12,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8.0), // Add top margin for floating label
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: borderColor),
            boxShadow: [AppTheme.lightShadow],
          ),
          child: Stack(
            children: [
              // Label
              if (widget.label != null)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final isFloating = _animationController.value > 0.5;
                    return Positioned(
                      left: 14,
                      top: _positionAnimation.value,
                      child: Container(
                        padding: isFloating 
                            ? const EdgeInsets.symmetric(horizontal: 4.0)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: isFloating 
                              ? (widget.disabled ? AppTheme.greyLight : AppTheme.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isFloating ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ] : null,
                        ),
                        child: Text(
                          widget.label!,
                          style: TextStyle(
                            fontSize: _sizeAnimation.value,
                            color: _colorAnimation.value,
                            fontWeight: isFloating ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Input field
              Padding(
                padding: padding,
                child: Row(
                  crossAxisAlignment: widget.multiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    // Left icon
                    if (widget.iconPosition == 'left' && widget.icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: widget.icon,
                      ),

                    // TextField
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: widget.textStyle ??
                            TextStyle(
                              fontSize: 16,
                              color: AppTheme.dark,
                            ),
                        decoration: widget.decoration?.copyWith(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: _isFocused ? widget.placeholder : null,
                              hintStyle: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 16,
                              ),
                            ) ??
                            InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: _isFocused ? widget.placeholder : null,
                              hintStyle: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 16,
                              ),
                            ),
                        keyboardType: widget.multiline
                            ? TextInputType.multiline
                            : widget.keyboardType,
                        textCapitalization: widget.textCapitalization,
                        obscureText: widget.obscureText && !_isPasswordVisible,
                        enabled: !widget.disabled && !widget.readOnly,
                        readOnly: widget.readOnly,
                        maxLength: widget.maxLength,
                        minLines: widget.multiline ? widget.minLines ?? 3 : 1,
                        maxLines: widget.multiline ? widget.maxLines ?? 5 : 1,
                        textAlignVertical: widget.multiline
                            ? TextAlignVertical.top
                            : TextAlignVertical.center,
                      ),
                    ),

                    // Right icon
                    if (widget.iconPosition == 'right' &&
                        widget.icon != null &&
                        !widget.obscureText)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: widget.icon,
                      ),

                    // Password visibility toggle
                    if (widget.obscureText)
                      GestureDetector(
                        onTap: _togglePasswordVisibility,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            _isPasswordVisible ? 'Hide' : 'Show',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Error message
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              widget.error!,
              style: TextStyle(
                color: AppTheme.danger,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
