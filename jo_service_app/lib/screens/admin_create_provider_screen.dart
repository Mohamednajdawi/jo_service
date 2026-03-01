import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminCreateProviderScreen extends StatefulWidget {
  static const routeName = '/admin/create-provider';

  const AdminCreateProviderScreen({super.key});

  @override
  State<AdminCreateProviderScreen> createState() => _AdminCreateProviderScreenState();
}

class _AdminCreateProviderScreenState extends State<AdminCreateProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Controllers for form fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedServiceType;
  bool _isLoading = false;
  String? _adminToken;

  // Service types available
  final List<String> _serviceTypes = [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Gardening',
    'Moving',
    'Handyman',
    'HVAC',
    'Pest Control',
    'Home Repair',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminToken();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _hourlyRateController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    _adminToken = prefs.getString('admin_token');
    
    if (_adminToken == null) {
      // No admin token, redirect to login
      Navigator.of(context).pushReplacementNamed('/admin-login');
    }
  }

  Future<void> _createProvider() async {
    if (!_formKey.currentState!.validate() || _adminToken == null) {
      return;
    }

    // Additional validation for service type
    if (_selectedServiceType == null || _selectedServiceType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service type'),
          backgroundColor: Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
    final providerData = {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'services': [_selectedServiceType], // Convert string to array as backend expects
      'location': {
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
      },
      'description': _bioController.text.trim(),
      'businessName': _companyNameController.text.trim(),
      'hourlyRate': double.tryParse(_hourlyRateController.text.trim()) ?? 25.0,
    };

      // Debug logging

      await _apiService.createProviderAccount(_adminToken!, providerData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider account created successfully!'),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Navigate back to dashboard
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating provider: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Provider',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF000000),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createProvider,
            child: Text(
              'Create',
              style: TextStyle(
                color: _isLoading ? const Color(0xFF8E8E93) : const Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _emailController,
                label: 'Email (must end with @joprovider.com)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.trim().endsWith('@joprovider.com')) {
                    return 'Email must end with @joprovider.com';
                  }
                  if (!RegExp(r'^[^@]+@joprovider\.com$').hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Company Information Section
              _buildSectionHeader('Company Information'),
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _companyNameController,
                label: 'Company Name',
                icon: Icons.business_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Service Type Dropdown
              _buildDropdownField(
                value: _selectedServiceType,
                label: 'Service Type',
                icon: Icons.work_outline,
                items: _serviceTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Service type is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _hourlyRateController,
                label: 'Hourly Rate (JOD)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hourly rate is required';
                  }
                  final rate = double.tryParse(value.trim());
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid hourly rate';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Location Information Section
              _buildSectionHeader('Location Information'),
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _addressController,
                label: 'Full Address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Additional Information Section
              _buildSectionHeader('Additional Information'),
              const SizedBox(height: 16),
              
              _buildTextFormField(
                controller: _bioController,
                label: 'Bio/Description (Optional)',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: null, // Optional field
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProvider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Provider Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF000000),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF000000),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF007AFF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF3B30),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF3B30),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF000000),
      ),
      dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF007AFF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF3B30),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF3B30),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
          ),
        );
      }).toList(),
    );
  }
}
