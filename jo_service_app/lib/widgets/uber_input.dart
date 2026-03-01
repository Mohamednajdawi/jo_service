import 'package:flutter/material.dart';

class UberInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;

  const UberInput({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<UberInput> createState() => _UberInputState();
}

class _UberInputState extends State<UberInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasContent = widget.controller.text.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 5),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isFocused 
                  ? (isDark ? Colors.white : const Color(0xFF000000))
                  : (isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6B7280)),
            ),
          ),
        ),
        
        // Input Field
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused 
                  ? (isDark ? Colors.white : const Color(0xFF000000))
                  : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB)),
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText && !_isPasswordVisible,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            enabled: widget.enabled,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            readOnly: widget.readOnly,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF000000),
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Text(
                        _isPasswordVisible ? 'Hide' : 'Show',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF000000),
                        ),
                      ),
                      onPressed: _togglePasswordVisibility,
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
} 