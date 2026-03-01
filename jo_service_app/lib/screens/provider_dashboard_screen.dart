import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/theme.dart';
import '../constants/api_config.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../services/booking_service.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart' as model;
import './user_login_screen.dart';
import './edit_provider_profile_screen.dart';
import './provider_bookings_screen.dart';
import './provider_messages_screen.dart';
import 'package:provider/provider.dart';

/// Builds a URL that the app can load for a profile image (provider or user).
String? _profileImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final base = ApiConfig.productionBaseUrl;
  if (url.startsWith(base)) return url;
  if (url.startsWith('http')) return url;
  if (!url.startsWith('/')) return 'https://$url';
  return '$base$url';
}

class ProviderDashboardScreen extends StatefulWidget {
  static const routeName = '/provider-dashboard';

  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with WidgetsBindingObserver {
  // Booking statistics
  int _activeBookings = 0;
  int _completedThisMonth = 0;
  bool _isLoadingStats = true;
  final BookingService _bookingService = BookingService();
  
  // Auto-refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);
  
  // Previous booking counts for comparison
  int _previousActiveBookings = 0;
  int _previousCompletedThisMonth = 0;
  
  // Auto-refresh indicator
  bool _isAutoRefreshActive = true;
  
  // Provider profile and availability
  model.Provider? _provider;
  bool _isProviderAvailable = true;
  bool _isUpdatingAvailability = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);

    // Load booking statistics and provider profile
    _loadBookingStatistics();
    _loadProviderProfile();
    
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        if (_isAutoRefreshActive) {
          _startAutoRefresh();
          // Refresh data immediately when app resumes
          _loadBookingStatistics();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background
        _stopAutoRefresh();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., receiving a phone call)
        break;
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _loadBookingStatistics();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadBookingStatistics() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final providerId = await authService.getUserId();

      if (token == null || providerId == null) {
        return;
      }

      // Fetch active bookings (pending, accepted, in_progress)
      final activeBookingsResult = await _bookingService.getProviderBookings(
        token: token,
        status: null, // Get all bookings
        page: 1,
        limit: 100, // Get more to count properly
      );

      final List<dynamic> allBookings = activeBookingsResult['bookings'] ?? [];
      
      // Count active bookings
      int activeCount = 0;
      int completedThisMonth = 0;
      
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var booking in allBookings) {
        // The booking service returns Booking objects, not raw JSON maps
        final status = booking.status;
        final createdAt = booking.createdAt;

        // Count active bookings
        if (status == 'pending' || status == 'accepted' || status == 'in_progress') {
          activeCount++;
        }

        // Count completed this month
        if (status == 'completed' && createdAt != null && createdAt.isAfter(startOfMonth)) {
          completedThisMonth++;
        }
      }

      
      // Check for new bookings
      bool hasNewBookings = false;
      if (activeCount > _previousActiveBookings && _previousActiveBookings > 0) {
        hasNewBookings = true;
        _showNewBookingNotification(activeCount - _previousActiveBookings);
      }
      
      if (mounted) {
        setState(() {
          _activeBookings = activeCount;
          _completedThisMonth = completedThisMonth;
          _isLoadingStats = false;
        });
        
        // Update previous counts
        _previousActiveBookings = activeCount;
        _previousCompletedThisMonth = completedThisMonth;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoadingStats = true;
    });
    await _loadBookingStatistics();
    await _loadProviderProfile();
  }

  Future<void> _loadProviderProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      if (token == null) {
        return;
      }
      
      final profile = await _apiService.getMyProviderProfile(token);
      
      if (mounted) {
        setState(() {
          _provider = profile;
          _isProviderAvailable = profile.isAvailable ?? true;
        });
      }
    } catch (e) {
      // Silently fail for now, don't show error for this background operation
      print('Error loading provider profile: $e');
    }
  }

  Future<void> _updateProviderAvailability(bool newAvailability) async {
    if (_isUpdatingAvailability) return;
    
    setState(() {
      _isUpdatingAvailability = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      // Use the dedicated availability endpoint
      await _apiService.updateProviderAvailability(token, newAvailability);
      
      setState(() {
        _isProviderAvailable = newAvailability;
      });
      
      // Show success feedback
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newAvailability ? Icons.check_circle : Icons.pause_circle_filled,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  newAvailability 
                    ? l10n.nowAvailable 
                    : l10n.nowUnavailable,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: newAvailability 
            ? AppTheme.primary 
            : const Color(0xFFFF9500),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to update availability: ${e.toString()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF3B30),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isUpdatingAvailability = false;
      });
    }
  }

  void _showNewBookingNotification(int newBookingsCount) {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.newBookingNotification(newBookingsCount, newBookingsCount > 1 ? 's' : ''),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: l10n.view,
            textColor: Colors.white,
            onPressed: () => _navigateToBookings(context),
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader(model.Provider? provider) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = provider != null
        ? (provider.companyName ?? provider.fullName ?? l10n.profile)
        : l10n.profile;
    final email = provider?.email ?? '';
    final pictureUrl = _profileImageUrl(provider?.profilePictureUrl);

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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isProviderAvailable
                    ? [AppTheme.primary, AppTheme.secondary]
                    : [AppTheme.grey, AppTheme.greyLight],
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
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: pictureUrl == null || pictureUrl.isEmpty
                      ? Icon(
                          _isProviderAvailable
                              ? Icons.person_rounded
                              : Icons.person_off_rounded,
                          size: 40,
                          color: AppTheme.grey,
                        )
                      : Image.network(
                          pictureUrl,
                          key: ValueKey(pictureUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppTheme.grey,
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2));
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: AppTheme.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
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
                  Expanded(
                    child: Text(
                      email,
                      style: AppTheme.body3.copyWith(color: AppTheme.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Availability row (same style as user profile tiles)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isProviderAvailable
                  ? AppTheme.primary.withOpacity(0.08)
                  : AppTheme.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isProviderAvailable
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.warning.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isProviderAvailable
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled,
                  size: 20,
                  color: _isProviderAvailable
                      ? AppTheme.primary
                      : AppTheme.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.availabilityStatus,
                        style: AppTheme.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.dark,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _isProviderAvailable
                            ? l10n.availableForBookings
                            : l10n.currentlyUnavailable,
                        style: AppTheme.body3.copyWith(
                          color: AppTheme.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUpdatingAvailability)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  )
                else
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: _isProviderAvailable,
                      onChanged: (value) => _updateProviderAvailability(value),
                      activeColor: AppTheme.primary,
                    ),
                  ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.light,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.profile,
          style: AppTheme.h3.copyWith(
            color: AppTheme.dark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.dark, size: 22),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: Icon(Icons.translate, color: AppTheme.dark, size: 22),
            onPressed: () async {
              final localeService =
                  Provider.of<LocaleService>(context, listen: false);
              await localeService.toggleLocale();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.languageChanged),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.dark, size: 22),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, authService);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.signOut),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(_provider),
            // Stats row (compact, same card style as user)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.pending,
                      l10n.bookings,
                      Icons.schedule_rounded,
                      AppTheme.primary,
                      false,
                      _isLoadingStats ? '...' : _activeBookings.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      l10n.completed,
                      l10n.completedThisMonth,
                      Icons.check_circle_rounded,
                      AppTheme.primary,
                      false,
                      _isLoadingStats ? '...' : _completedThisMonth.toString(),
                    ),
                  ),
                ],
              ),
            ),
            _buildAppleStyleCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: l10n.manageProfile,
                  subtitle: l10n.updateServicesRates,
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
                  onTap: () => _navigateToProfile(context),
                ),
                _buildSettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: l10n.manageBookings,
                  subtitle: l10n.viewRespondBookings,
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
                  onTap: () => _navigateToBookings(context),
                ),
                _buildSettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: l10n.messages,
                  subtitle: l10n.viewRespondMessages,
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
                  onTap: () => _navigateToMessages(context),
                  isLast: true,
                  iconColor: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: l10n.logout,
              onPressed: () => _showLogoutDialog(context, authService),
              color: AppTheme.warning,
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppTheme.dark,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EditProviderProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToBookings(BuildContext context) {
                Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProviderBookingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToMessages(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProviderMessagesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.signOut,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.areYouSureSignOut,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const UserLoginScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                l10n.signOut,
                style: const TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.deleteAccount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF3B30),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deleteAccountConfirmation,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.deleteAccountWarning,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount(context, authService);
              },
              child: Text(
                l10n.delete,
                style: const TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context, AuthService authService) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );
      
      await authService.deleteAccount();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeleted),
            backgroundColor: AppTheme.primary,
          ),
        );
        
        // Navigate to user login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const UserLoginScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if it's open
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToDeleteAccount}: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}
