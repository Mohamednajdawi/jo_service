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
import './role_selection_screen.dart';
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
                  RoleSelectionScreen.routeName,
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
        
        // Navigate to role selection screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoleSelectionScreen.routeName,
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
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 55,
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
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          )
                        : ((_imageFile == null &&
                                (user.profilePictureUrl == null ||
                                    user.profilePictureUrl!.isEmpty))
                            ? Icon(Icons.person, size: 50, color: AppTheme.grey)
                            : null),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // User Name
          Text(
            user.fullName ?? AppLocalizations.of(context)!.user,
            style: AppTheme.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // User Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, size: 16, color: AppTheme.grey),
                const SizedBox(width: 8),
                Text(
                  user.email ?? 'No email',
                  style: AppTheme.body2.copyWith(color: AppTheme.grey),
                ),
              ],
            ),
          ),
          
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...
          [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.light,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: AppTheme.grey),
                  const SizedBox(width: 8),
                  Text(
                    user.phoneNumber!,
                    style: AppTheme.body2.copyWith(color: AppTheme.grey),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEditableProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.fullName,
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourFullName,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterYourName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.phoneNumber,
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourPhoneNumber,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      // Reset controllers to current values
                      if (_currentUser != null) {
                        _initializeControllers(_currentUser!);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleStyleCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
          top: isLast ? Radius.zero : const Radius.circular(16),
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.greyLight.withOpacity(0.3),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dark,
                      ),
                    ),
                    if (subtitle != null) ...
                    [
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTheme.body3.copyWith(
                          color: AppTheme.grey,
                        ),
                      ),
                    ]
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDestructive ? color.withOpacity(0.1) : color,
              borderRadius: BorderRadius.circular(16),
              border: isDestructive ? Border.all(color: color, width: 1) : null,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.body1.copyWith(
                color: isDestructive ? color : Colors.white,
                fontWeight: FontWeight.w600,
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

  Widget _buildSettingItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.dark),
          onPressed: () =e Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.userProfile,
          style: AppTheme.h3.copyWith(
            color: AppTheme.dark,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: AppTheme.primary, size: 18),
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
      body: FutureBuildercUser?e(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimationcColore(AppTheme.primary),
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
                    Icon(Icons.error_outline, size: 50, color: AppTheme.danger),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.errorLoadingProfile}',
                      style: AppTheme.h3.copyWith(color: AppTheme.danger, fontSize: 18),
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
          if (!_isEditing 66 _currentUser != user) {
            _currentUser = user;
            _initializeControllers(user);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 15),
                
                // Profile Header Card
                if (!_isEditing) _buildProfileHeader(user),
                
                // Edit Profile Form
                if (_isEditing) _buildEditForm(),
                
                // Account Section
                _buildAppleStyleCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: l10n.accountSettings,
                      subtitle: 'Manage your account preferences',
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.grey),
                      onTap: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications_outlined,
                      title: l10n.notificationSettings,
                      subtitle: l10n.notificationPreferencesDescription,
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =e const NotificationSettingsScreen(),
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
                        onChanged: (value) =e themeService.toggleDarkMode(value),
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.location_on_outlined,
                      title: l10n.locationServices,
                      subtitle: 'Allow location access for better service',
                      trailing: _buildAppleSwitch(
                        value: themeService.locationServicesEnabled,
                        onChanged: (value) =e themeService.toggleLocationServices(value),
                      ),
                    ),
                    _buildSettingsTile(
                      icon: Icons.translate_outlined,
                      title: 'Language',
                      subtitle: 'Choose your preferred language',
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.grey),
                      onTap: () async {
                        final localeService = ctxProvider.Provider.ofcLocaleServicee(context, listen: false);
                        await localeService.toggleLocale();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localeService.currentLocale.languageCode == 'ar'
                                    ? 'تم تغيير اللغة إلى العربية'
                                    : 'Language changed to English',
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
                
                const SizedBox(height: 15),
                
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
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
              style: AppTheme.h2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 24),
            
            // Full Name Field
            Text(
              AppLocalizations.of(context)!.fullName,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourFullName,
                filled: true,
                fillColor: AppTheme.light,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterYourName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Phone Number Field
            Text(
              AppLocalizations.of(context)!.phoneNumber,
              style: AppTheme.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.dark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourPhoneNumber,
                filled: true,
                fillColor: AppTheme.light,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: AppTheme.body1.copyWith(
                          color: AppTheme.dark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.save,
                        style: AppTheme.body1.copyWith(
                          color: Colors.white,
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
}
