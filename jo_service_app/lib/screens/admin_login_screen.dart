import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart'; // Add API service import
import '../widgets/uber_input.dart';
import './admin_dashboard_screen.dart';
import './user_login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add for storing admin token

class AdminLoginScreen extends StatefulWidget {
  static const routeName = '/admin-login';

  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // Add API service instance

  bool _isLoading = false;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Use real API for admin authentication
        final response = await _apiService.adminLogin(
          _emailController.text,
          _passwordController.text,
        );

        // Store admin token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', response['token']);
        await prefs.setString('admin_email', response['user']['email']);

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context)
            .pushReplacementNamed(AdminDashboardScreen.routeName);
            
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : const Color(0xFF000000),
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(UserLoginScreen.routeName);
          },
        ),
        title: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40),
                
                // Admin Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF007AFF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: const Color(0xFF007AFF),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ADMIN ACCESS',
                        style: TextStyle(
                          color: const Color(0xFF007AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Main Title
                Text(
                  'Admin Portal',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage providers and verify accounts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Demo Credentials Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF34C759).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF34C759),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Demo Credentials',
                            style: TextStyle(
                              color: const Color(0xFF34C759),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: admin@joservice.com\nPassword: admin123',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Email Input
                UberInput(
                  label: 'Admin email',
                  hint: 'Enter admin email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                
                const SizedBox(height: 24),
                
                // Password Input
                UberInput(
                  label: 'Password',
                  hint: 'Enter admin password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                
                const SizedBox(height: 32),
                
                // Error Message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: const Color(0xFFFF3B30),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
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
                  ),
                
                // Admin Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: isDark 
                          ? const Color(0xFF38383A) 
                          : const Color(0xFFF3F4F6),
                      disabledForegroundColor: isDark 
                          ? const Color(0xFF8E8E93) 
                          : const Color(0xFF9CA3AF),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Access Admin Portal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Back to Main App Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(UserLoginScreen.routeName);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF000000),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                        children: [
                          const TextSpan(text: "Back to "),
                          TextSpan(
                            text: 'main app',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF000000),
                              fontWeight: FontWeight.w600,
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
    );
  }
} 