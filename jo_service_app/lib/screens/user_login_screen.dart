import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/api_service.dart';
import './user_signup_screen.dart';
import './user_home_screen.dart';
import './admin_login_screen.dart';
import './user_verification_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserLoginScreen extends StatefulWidget {
  static const routeName = '/user-login';

  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.emailRequired;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.enterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 6) {
      return l10n.passwordMinLength;
    }
    return null;
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.loginWithGoogle();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(UserHomeScreen.routeName);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        // Check if it's a provider email
        if (email.endsWith('@joprovider.com')) {
          // Provider login flow
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.loginProvider(email: email, password: password);
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/provider-dashboard');
          }
        } else {
          // Regular user login flow
          final authService = Provider.of<AuthService>(context, listen: false);
          final loginResponse = await authService.loginUser(email: email, password: password);
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(UserHomeScreen.routeName);
          }
        }
        
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          String errorMsg = e.toString().replaceFirst('Exception: ', '');
          
          // Handle verification errors specifically
          if (errorMsg.contains('Account not fully verified')) {
            _errorMessage = 'Please verify your email and phone number before logging in. Check your email for verification links.';
            // Navigate to verification screen with proper user info
            if (mounted) {
              Future.delayed(const Duration(seconds: 2), () async {
                // Get the user ID from auth service
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = await authService.getUserId();
                
                Navigator.of(context).pushNamed(
                  UserVerificationScreen.routeName,
                  arguments: {
                    'userId': userId ?? _emailController.text.trim(),
                    'userEmail': _emailController.text.trim(),
                    'isEmailVerification': false,
                  },
                );
              });
            }
          } else if (errorMsg.contains('Account has been suspended')) {
            _errorMessage = 'Account has been suspended. Please contact support.';
          } else {
            _errorMessage = errorMsg;
          }
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.getBaseUrl()}/auth/user/resend-email-verification'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          _errorMessage = null;
        });
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.verificationEmailSent),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to resend verification email';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend verification email: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              // Language toggle button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1C1C1E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language, 
                        size: 18,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localeService.currentLocaleDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () => localeService.toggleLocale(),
                  tooltip: l10n.changeLanguage,
                ),
              ),
              // Admin access button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1C1C1E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.admin_panel_settings,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pushReplacementNamed(AdminLoginScreen.routeName);
                  },
                  tooltip: l10n.administrator,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      

                      
                      // Welcome text
                      Text(
                        l10n.signInToAccount,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF000000),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Welcome back! Please sign in to your account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDark 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Social Login Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1C1C1E) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Continue with',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark 
                                    ? const Color(0xFF8E8E93) 
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleLogin,
                                icon: const Icon(
                                  Icons.g_mobiledata, 
                                  color: Color(0xFFEA4335),
                                  size: 24,
                                ),
                                label: Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF000000),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark 
                                        ? const Color(0xFF38383A) 
                                        : const Color(0xFFE5E7EB),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark 
                                  ? const Color(0xFF38383A) 
                                  : const Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or sign in with email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark 
                                    ? const Color(0xFF8E8E93) 
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark 
                                  ? const Color(0xFF38383A) 
                                  : const Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Email field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1C1C1E) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF000000),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            labelStyle: TextStyle(
                              color: isDark 
                                  ? const Color(0xFF8E8E93) 
                                  : const Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: isDark 
                                  ? const Color(0xFF8E8E93) 
                                  : const Color(0xFF6B7280),
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF34C759),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF3B30),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                      ),
                     
                      const SizedBox(height: 20),
                     
                      // Password field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1C1C1E) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF000000),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            labelStyle: TextStyle(
                              color: isDark 
                                  ? const Color(0xFF8E8E93) 
                                  : const Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: isDark 
                                  ? const Color(0xFF8E8E93) 
                                  : const Color(0xFF6B7280),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark 
                                    ? const Color(0xFF8E8E93) 
                                    : const Color(0xFF6B7280),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF34C759),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF3B30),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                      ),
                    
                      const SizedBox(height: 16),
                    
                      // Forgot password
                      Align(
                        alignment: localeService.isRTL 
                            ? Alignment.centerLeft 
                            : Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Handle forgot password
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            foregroundColor: const Color(0xFF34C759),
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    
                      const SizedBox(height: 32),
                    
                      // Error message display
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF3B30).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFFF3B30),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Show resend verification link for verification errors
                              if (_errorMessage!.contains('Account not fully verified') ||
                                  _errorMessage!.contains('Please verify your email'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _resendVerificationEmail,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: const Color(0xFF34C759),
                                    ),
                                    child: Text(
                                      l10n.resendVerificationEmail,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    
                      // Login button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF34C759).withOpacity(0.3),
                              offset: const Offset(0, 8),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  l10n.login,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    
                      const SizedBox(height: 32),
                    
                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark 
                                  ? const Color(0xFF8E8E93) 
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed(UserSignUpScreen.routeName);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              foregroundColor: const Color(0xFF34C759),
                            ),
                            child: Text(
                              l10n.signup,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
