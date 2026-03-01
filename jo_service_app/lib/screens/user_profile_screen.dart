import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';
import './user_login_screen.dart';
import './notification_settings_screen.dart';
import '../constants/theme.dart';
import 'dart:ui';

class UserProfileScreen extends StatefulWidget {
  static const routeName = '/user-profile';

  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  Future<User?>? _userProfileFuture;
  User? _currentUser;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers for editable fields
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
      }
    });
  }

  void _loadProfile() async {
    final authService =
        ctxProvider.Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.authenticationTokenNotFound)),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
      setState(() {
        _userProfileFuture =
            Future.error(Exception('Authentication token not found.'));
      });
      return;
    }
    setState(() {
      _userProfileFuture = _apiService.getMyUserProfile(token).then((user) {
        if (user != null) {
          _currentUser = user;
          _initializeControllers(user);
        }
        return user;
      });
    });
  }

  void _initializeControllers(User user) {
    _fullNameController.text = user.fullName ?? '';
    _phoneNumberController.text = user.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null || token.isEmpty || _currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.authenticationError)),
          );
        }
        return;
      }

      final Map<String, dynamic> updatedData = {
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneNumberController.text,
      };

      try {
        final updatedUser =
            await _apiService.updateMyUserProfile(token, updatedData);

        setState(() {
          _currentUser = updatedUser;
          _initializeControllers(updatedUser);
          _isEditing = false;
          _userProfileFuture = Future.value(updatedUser);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateProfile}: $e')),
          );
        }
      }
    }
  }

  // Add method to pick image from gallery
  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.imageUploadNotSupportedWeb)),
      );
      return;
    }

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorPickingImage}: $e')),
        );
      }
    }
  }

  // Add method to upload profile picture
  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    try {
      setState(() {
        _isUploading = true;
      });

      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.authenticationError)),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final updatedUser =
          await _apiService.uploadUserProfilePicture(token, _imageFile!);
      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
          _isUploading = false;
          _imageFile = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.profilePictureUploadedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUploadProfilePicture}: $e')),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmLogout),
        content: Text(l10n.areYouSureLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService =
                  ctxProvider.Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  UserLoginScreen.routeName,
                  (route) => false,
                );
              }
            },
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountConfirmation),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deleteAccountWarning,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text(AppLocalizations.of(context)!.deletingAccount),
              ],
            ),
          ),
        );
      }
      
      await authService.deleteAccount();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeleted),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to user login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          UserLoginScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if it's open
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToDeleteAccount}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar with gradient border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppTheme.light,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider<Object>
                        : (user.profilePictureUrl != null &&
                                user.profilePictureUrl!.isNotEmpty &&
                                user.profilePictureUrl!.startsWith('http')
                            ? NetworkImage(user.profilePictureUrl!)
                            : null),
                    child: _isUploading
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          )
                        : ((_imageFile == null &&
                                (user.profilePictureUrl == null ||
                                    user.profilePictureUrl!.isEmpty))
                            ? Icon(Icons.person, size: 40, color: AppTheme.grey)
                            : null),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // User Name
          Text(
            user.fullName ?? AppLocalizations.of(context)!.user,
            style: AppTheme.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // User Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, size: 14, color: AppTheme.grey),
                const SizedBox(width: 6),
                Text(
                  user.email ?? 'No email',
                  style: AppTheme.body3.copyWith(color: AppTheme.grey),
                ),
              ],
            ),
          ),
          
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.light,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: AppTheme.grey),
                  const SizedBox(width: 6),
                  Text(
                    user.phoneNumber!,
                    style: AppTheme.body3.copyWith(color: AppTheme.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppleStyleCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isLast ? Radius.zero : const Radius.circular(12),
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.greyLight.withOpacity(0.2),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.dark,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppTheme.body3.copyWith(
                          color: AppTheme.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing widget
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required VoidCallback onPressed,
    required Color color,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDestructive ? color.withOpacity(0.1) : color,
              borderRadius: BorderRadius.circular(12),
              border: isDestructive ? Border.all(color: color, width: 1) : null,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.body1.copyWith(
                color: isDestructive ? color : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleSwitch({required bool value, required Function(bool) onChanged}) {
    return Transform.scale(
      scale: 0.8,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: AppTheme.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 20),
            
            // Full Name Field
            Text(
              AppLocalizations.of(context)!.fullName,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourFullName,
                filled: true,
                fillColor: AppTheme.light,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterYourName;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            
            // Phone Number Field
            Text(
              AppLocalizations.of(context)!.phoneNumber,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourPhoneNumber,
                filled: true,
                fillColor: AppTheme.light,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          if (_currentUser != null) {
                            _initializeControllers(_currentUser!);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greyLight,
                        foregroundColor: AppTheme.dark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = ctxProvider.Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.light,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.userProfile,
          style: AppTheme.h3.copyWith(
            color: AppTheme.dark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: AppTheme.primary, size: 16),
                ),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
            ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.errorLoadingProfile}',
                      style: AppTheme.h3.copyWith(color: AppTheme.danger, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      style: AppTheme.body3.copyWith(color: AppTheme.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                l10n.couldNotLoadProfile,
                style: AppTheme.h3.copyWith(color: AppTheme.grey),
              ),
            );
          }

          final user = snapshot.data!;
          if (!_isEditing && _currentUser != user) {
            _currentUser = user;
            _initializeControllers(user);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // Profile Header Card
                if (!_isEditing) _buildProfileHeader(user),
                
                // Edit Profile Form
                if (_isEditing) _buildEditForm(),
                
                // Account Section
                _buildAppleStyleCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: l10n.notificationSettings,
                      subtitle: l10n.notificationPreferencesDescription,
                      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                      isLast: true,
                    ),
                  ],
                ),
                
                // Preferences Section
                _buildAppleStyleCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.darkMode,
                      subtitle: 'Switch between light and dark themes',
                      trailing: _buildAppleSwitch(
                        value: themeService.darkModeEnabled,
                        onChanged: (value) => themeService.toggleDarkMode(value),
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.location_on_outlined,
                      title: l10n.locationServices,
                      subtitle: 'Allow location access for better service',
                      trailing: _buildAppleSwitch(
                        value: themeService.locationServicesEnabled,
                        onChanged: (value) => themeService.toggleLocationServices(value),
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.translate_outlined,
                      title: 'Language',
                      subtitle: 'Choose your preferred language',
                      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
                      onTap: () async {
                        final localeService = ctxProvider.Provider.of<LocaleService>(context, listen: false);
                        await localeService.toggleLocale();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.languageChanged,
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                      isLast: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action Buttons
                if (_isEditing)
                  _buildActionButton(
                    title: l10n.deleteAccount,
                    onPressed: _handleDeleteAccount,
                    color: AppTheme.danger,
                    isDestructive: true,
                  ),
                _buildActionButton(
                  title: l10n.logout,
                  onPressed: _handleLogout,
                  color: AppTheme.warning,
                  isDestructive: true,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
