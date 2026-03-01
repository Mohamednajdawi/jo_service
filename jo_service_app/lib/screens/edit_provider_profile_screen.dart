import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart';
import '../widgets/location_picker.dart';

class EditProviderProfileScreen extends StatefulWidget {
  const EditProviderProfileScreen({super.key});

  @override
  State<EditProviderProfileScreen> createState() => _EditProviderProfileScreenState();
}

class _EditProviderProfileScreenState extends State<EditProviderProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;
  File? _selectedImage;
  String? _currentProfilePictureUrl;
  bool _hasUnsavedChanges = false;
  
  // Original data for comparison
  String _originalBusinessName = '';
  String _originalDescription = '';
  String _originalServices = '';
  String _originalHourlyRate = '';
  String _originalPhone = '';
  String _originalAddress = '';
  
  // Location data
  double? _latitude;
  double? _longitude;
  String _selectedAddress = '';

  // Form controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servicesController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    
    _loadProviderProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _servicesController.dispose();
    _hourlyRateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderProfile() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = provider_package.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final userId = await authService.getUserId();


      if (token == null || userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.editProfileAuthenticationError)),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final provider = await _apiService.getMyProviderProfile(token);

      if (mounted) {
        setState(() {
          _businessNameController.text = provider.companyName ?? provider.fullName ?? '';
          _descriptionController.text = provider.serviceDescription ?? '';
          _servicesController.text = provider.serviceType ?? '';
          _hourlyRateController.text = provider.hourlyRate?.toString() ?? '';
          _phoneController.text = provider.contactInfo?.phone ?? '';
          _addressController.text = provider.location?.addressText ?? '';
          _selectedAddress = provider.location?.addressText ?? '';
          if (provider.location?.coordinates != null && provider.location!.coordinates!.length >= 2) {
            _longitude = provider.location!.coordinates![0];
            _latitude = provider.location!.coordinates![1];
            
            // Log loaded location data
            print('📍 Location Data Loaded:');
            print('   Address: ${provider.location?.addressText}');
            print('   Coordinates: ${provider.location?.coordinates}');
            print('   Latitude: $_latitude');
            print('   Longitude: $_longitude');
          }
          _currentProfilePictureUrl = provider.profilePictureUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.editProfileErrorLoading(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProfileImageUploadWebNotSupported),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProfileErrorPickingImage(e.toString())),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProfileCameraWebNotSupported),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.editProfileErrorTakingPhoto(e.toString())),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImage == null) return;

      setState(() {
        _isUploading = true;
      });

    try {
      final authService = provider_package.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(AppLocalizations.of(context)!.editProfileAuthenticationError),
            backgroundColor: Color(0xFFFF3B30),
          ),
          );
        return;
      }

      final updatedProvider = await _apiService.uploadProfilePicture(token, _selectedImage!);
      
      if (updatedProvider != null) {
        setState(() {
          _currentProfilePictureUrl = updatedProvider.profilePictureUrl;
          _selectedImage = null; // Clear selected image after successful upload
          _isUploading = false;
        });

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profilePictureUploadedSuccessfully),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorUploadingProfilePicture}: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = provider_package.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final userId = await authService.getUserId();


      if (token == null || userId == null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authenticationErrorPleaseLogin)),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final updatedData = {
        'fullName': _businessNameController.text.trim(),
        'businessName': _businessNameController.text.trim(), // Backend expects 'businessName' not 'companyName'
        'serviceDescription': _descriptionController.text.trim(),
        'serviceType': _servicesController.text.trim(),
        'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0.0,
        'phoneNumber': _phoneController.text.trim(), // Backend expects 'phoneNumber' as direct field
        'location': {
          'address': _selectedAddress.isNotEmpty ? _selectedAddress : _addressController.text.trim(),
          'coordinates': _latitude != null && _longitude != null ? [_longitude!, _latitude!] : null,
        },
      };

      // Log the location data being sent
      final locationData = updatedData['location'] as Map<String, dynamic>?;
      print('📍 Location Data Being Sent:');
      print('   Address: ${locationData?['address']}');
      print('   Coordinates: ${locationData?['coordinates']}');
      print('   Latitude: $_latitude');
      print('   Longitude: $_longitude');

      // First update the profile data
      final updatedProvider = await _apiService.updateMyProviderProfile(token, updatedData);
      
      // If we have coordinates, also update the location separately
      Map<String, dynamic>? locationUpdateResponse;
      if (_latitude != null && _longitude != null) {
        try {
          locationUpdateResponse = await _apiService.updateProviderLocation(token, {
            'coordinates': [_longitude!, _latitude!],
            'address': _selectedAddress.isNotEmpty ? _selectedAddress : _addressController.text.trim(),
            'city': 'Amman', // Default city
            'country': 'US'
          });
          print('📍 Location coordinates updated successfully');
          print('📍 Location response: $locationUpdateResponse');
        } catch (e) {
          print('⚠️ Warning: Failed to update location coordinates: $e');
          // Don't fail the entire save if location update fails
        }
      }

      // Update form with server response, but use sent data for phone and address since server doesn't return them
      setState(() {
        _businessNameController.text = updatedProvider.companyName ?? updatedProvider.fullName ?? '';
        _descriptionController.text = updatedProvider.serviceDescription ?? '';
        _servicesController.text = updatedProvider.serviceType ?? '';
        _hourlyRateController.text = updatedProvider.hourlyRate?.toString() ?? '';
        // Keep the form data we sent since server doesn't return nested fields properly
        _phoneController.text = _phoneController.text; // Keep current form value
        _addressController.text = _addressController.text; // Keep current form value
        _currentProfilePictureUrl = updatedProvider.profilePictureUrl;
        _isSaving = false;
      });

      final l10n = AppLocalizations.of(context)!;
      
      // Create success message with location info
      String successMessage = l10n.profileUpdatedSuccessfully;
      
      // Add provider name to the message
      String providerName = updatedProvider.fullName ?? updatedProvider.companyName ?? 'Provider';
      
      // Add location update confirmation if coordinates were saved
      if (_latitude != null && _longitude != null && locationUpdateResponse != null) {
        final locationProvider = locationUpdateResponse['provider'];
        if (locationProvider != null) {
          final locationProviderName = locationProvider['fullName'] ?? locationProvider['businessName'] ?? locationProvider['companyName'] ?? 'Provider';
          successMessage = '✅ Profile updated successfully for $locationProviderName\n📍 Location saved with GPS coordinates';
        } else {
          successMessage = '✅ Profile updated successfully for $providerName\n📍 Location saved with GPS coordinates';
        }
      } else {
        successMessage = '✅ Profile updated successfully for $providerName';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF34C759),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorUpdatingProfile}: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  void _showLocationPicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectLocation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LocationPicker(
                initialAddress: _selectedAddress.isNotEmpty ? _selectedAddress : _addressController.text,
                onLocationSelected: (address, latitude, longitude) {
                  setState(() {
                    _selectedAddress = address;
                    _latitude = latitude;
                    _longitude = longitude;
                    _addressController.text = address;
                  });
                  
                  // Show confirmation dialog
                  final l10n = AppLocalizations.of(context)!;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('📍 Location Selected'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address: $address'),
                          const SizedBox(height: 8),
                          Text('Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✅ Location will be saved when you tap "Save Changes"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  
                  Navigator.pop(context); // Close location picker
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationInfo() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📍 Location Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${_selectedAddress.isNotEmpty ? _selectedAddress : _addressController.text}'),
            const SizedBox(height: 8),
            if (_latitude != null && _longitude != null) ...[
              Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
              const SizedBox(height: 4),
              Text('Longitude: ${_longitude!.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✅ GPS coordinates are saved and will be used for distance calculations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF34C759),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ No GPS coordinates saved. Tap the map icon to set your exact location.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF9500),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF007AFF)),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF007AFF)),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF007AFF),
                    ),
                  )
                : Column(
                    children: [
                      // Custom App Bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                ? Colors.black.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
          IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                size: 20,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: Text(
                                l10n.editProviderProfileTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (_isSaving)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF007AFF),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: _saveProfile,
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: const Color(0xFF007AFF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
          ),
        ],
      ),
                      ),
                      
                      // Form Content
                      Expanded(
            child: Form(
              key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              // Profile Header with Photo
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark 
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
              child: Column(
                                  children: [
                                    // Profile Picture Section
                                    Stack(
                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(60),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark 
                                                  ? Colors.black.withOpacity(0.3)
                                                  : Colors.black.withOpacity(0.1),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(60),
                                            child: _selectedImage != null
                                                ? Image.file(
                                                    _selectedImage!,
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                    height: 120,
                                                  )
                                                : _currentProfilePictureUrl != null && _currentProfilePictureUrl!.isNotEmpty && _currentProfilePictureUrl!.startsWith('http')
                                                    ? Image.network(
                                                        _currentProfilePictureUrl!,
                                                        fit: BoxFit.cover,
                                                        width: 120,
                                                        height: 120,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              gradient: const LinearGradient(
                                                                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.bottomRight,
                                                              ),
                                                              borderRadius: BorderRadius.circular(60),
                                                            ),
                                                            child: const Icon(
                                                              Icons.business_rounded,
                                                              color: Colors.white,
                                                              size: 50,
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    : Container(
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ),
                                                          borderRadius: BorderRadius.circular(60),
                                                        ),
                                                        child: const Icon(
                                                          Icons.business_rounded,
                                                          color: Colors.white,
                                                          size: 50,
                                                        ),
                                                      ),
                                          ),
                                        ),
                                        // Upload Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF007AFF),
                                              borderRadius: BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF007AFF).withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _showImagePickerDialog,
                                                borderRadius: BorderRadius.circular(18),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.editProfileBusinessProfile,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!.editProfileUpdateBusinessInfo,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                    // Upload Photo Button
                                    if (_selectedImage != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF34C759), Color(0xFF30D158)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF34C759).withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _isUploading ? null : _uploadProfilePicture,
                                            borderRadius: BorderRadius.circular(12),
                                            child: Center(
                                              child: _isUploading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : Text(
                                                      l10n.uploadPhoto,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Business Name
                              _buildInputField(
                                controller: _businessNameController,
                                label: l10n.businessName,
                                icon: Icons.business_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.businessNameRequired;
                                  }
                                  return null;
                                },
                                isDark: isDark,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Description
                              _buildInputField(
                                controller: _descriptionController,
                                label: l10n.description,
                                icon: Icons.description_rounded,
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.descriptionRequired;
                                  }
                                  return null;
                                },
                                isDark: isDark,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Services
                              _buildInputField(
                                controller: _servicesController,
                                label: l10n.services,
                                icon: Icons.miscellaneous_services_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.servicesRequired;
                                  }
                                  return null;
                                },
                                isDark: isDark,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Hourly Rate
                              _buildInputField(
                                controller: _hourlyRateController,
                                label: l10n.hourlyRate,
                                icon: Icons.attach_money_rounded,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.hourlyRateRequired;
                                  }
                                  if (double.tryParse(value) == null) {
                                    return l10n.enterValidNumber;
                                  }
                                  return null;
                                },
                                isDark: isDark,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Phone
                              _buildInputField(
                                controller: _phoneController,
                                label: l10n.phoneNumber,
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.phoneRequired;
                                  }
                                  return null;
                                },
                                isDark: isDark,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Location
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark 
                                        ? Colors.black.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.address,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedAddress.isNotEmpty ? _selectedAddress : _addressController.text,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                                  ),
                                                ),
                                                if (_latitude != null && _longitude != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.location_on,
                                                          size: 12,
                                                          color: const Color(0xFF34C759),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: const Color(0xFF34C759),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.map_rounded),
                                                onPressed: _showLocationPicker,
                                                color: const Color(0xFF007AFF),
                                              ),
                                              if (_latitude != null && _longitude != null)
                                                IconButton(
                                                  icon: const Icon(Icons.info_outline),
                                                  onPressed: () => _showLocationInfo(),
                                                  color: const Color(0xFF34C759),
                                                  tooltip: 'Location Info',
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Save Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF007AFF).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isSaving ? null : _saveProfile,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              l10n.saveChanges,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF007AFF),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFF3B30),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
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
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
