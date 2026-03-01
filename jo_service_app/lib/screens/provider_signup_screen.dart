import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../widgets/uber_input.dart';
import './provider_dashboard_screen.dart';

class ProviderSignUpScreen extends StatefulWidget {
  static const routeName = '/provider-signup';

  const ProviderSignUpScreen({super.key});

  @override
  State<ProviderSignUpScreen> createState() => _ProviderSignUpScreenState();
}

class _ProviderSignUpScreenState extends State<ProviderSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedCity = 'Amman'; // Default city
  final List<String> _cities = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Salt',
    'Madaba',
    'Jerash',
    'Ajloun',
    'Karak',
    'Tafilah',
    'Maan',
    'Mafraq'
  ];

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

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.fieldRequired;
    }
    return null;
  }

  String? _validateHourlyRate(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.hourlyRateRequired;
    }
    final rate = double.tryParse(value);
    if (rate == null || rate <= 0) {
      return l10n.enterValidRate;
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        // Create address text with city and detailed address
        final String fullAddress = _addressController.text.isNotEmpty
            ? '$_selectedCity, ${_addressController.text}'
            : _selectedCity;

        // IMPORTANT: Pass all required fields to registerProvider
        await authService.registerProvider(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          companyName: _companyNameController.text,
          serviceType: _serviceTypeController.text,
          hourlyRate: _hourlyRateController.text,
          city: _selectedCity,
          addressText: fullAddress,
        );
        setState(() {
          _isLoading = false;
        });
        // Navigate to dashboard screen after successful registration
        Navigator.of(context)
            .pushReplacementNamed(ProviderDashboardScreen.routeName);
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
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _companyNameController.dispose();
    _serviceTypeController.dispose();
    _hourlyRateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
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
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : const Color(0xFF000000),
              size: 18,
            ),
            onPressed: () {
              // Navigate back to provider login screen
              Navigator.of(context).pushReplacementNamed('/provider-login');
            },
          ),
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
                const SizedBox(height: 20),
                

                
                // Main Title
                Text(
                  l10n.joinAsProvider,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.startOfferingServices,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark 
                        ? const Color(0xFF8E8E93) 
                        : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Continue with email section
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
                        'Continue with email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fill in your details to create your provider account',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Personal Information Section
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: const Color(0xFF34C759),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.personalInformation,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF000000),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInputField(
                        label: l10n.fullName,
                        hint: l10n.enterFullName,
                        controller: _fullNameController,
                        validator: (value) => _validateRequired(value, l10n.fullName),
                        icon: Icons.person_outline,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        label: l10n.email,
                        hint: l10n.enterEmail,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        icon: Icons.email_outlined,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        label: l10n.password,
                        hint: l10n.enterPassword,
                        controller: _passwordController,
                        obscureText: true,
                        validator: _validatePassword,
                        icon: Icons.lock_outlined,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        label: l10n.confirmPassword,
                        hint: l10n.confirmYourPassword,
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: _validateConfirmPassword,
                        icon: Icons.lock_outlined,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Business Information Section
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business_outlined,
                              color: const Color(0xFF34C759),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.businessInformation,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF000000),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInputField(
                        label: l10n.companyName,
                        hint: l10n.enterCompanyName,
                        controller: _companyNameController,
                        validator: (value) => _validateRequired(value, l10n.companyName),
                        icon: Icons.business_outlined,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        label: l10n.serviceType,
                        hint: l10n.enterServiceType,
                        controller: _serviceTypeController,
                        validator: (value) => _validateRequired(value, l10n.serviceType),
                        icon: Icons.handyman_outlined,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        label: '${l10n.hourlyRate} (JOD)',
                        hint: l10n.enterHourlyRate,
                        controller: _hourlyRateController,
                        keyboardType: TextInputType.number,
                        validator: _validateHourlyRate,
                        icon: Icons.attach_money_outlined,
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // City Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.city,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark 
                                  ? const Color(0xFF8E8E93) 
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                            child: DropdownButtonFormField<String>(
                              value: _selectedCity,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white : const Color(0xFF000000),
                              ),
                              dropdownColor: isDark 
                                  ? const Color(0xFF1C1C1E) 
                                  : Colors.white,
                              items: _cities.map((String city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCity = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        label: l10n.address,
                        hint: l10n.enterDetailedAddress,
                        controller: _addressController,
                        validator: (value) => _validateRequired(value, l10n.address),
                        maxLines: 2,
                        icon: Icons.location_on_outlined,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Error Message
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
                    child: Row(
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
                  ),
                
                // Sign Up Button
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
                            l10n.createProviderAccount,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : const Color(0xFF000000),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark 
                ? const Color(0xFF8E8E93) 
                : const Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark 
                ? const Color(0xFF8E8E93) 
                : const Color(0xFF6B7280),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
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
        validator: validator,
      ),
    );
  }
}
