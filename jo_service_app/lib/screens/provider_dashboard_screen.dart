import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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

class ProviderDashboardScreen extends StatefulWidget {
  static const routeName = '/provider-dashboard';

  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
  
  // Provider availability state
  bool _isProviderAvailable = true;
  bool _isUpdatingAvailability = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: const Offset(0, 0.3),
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

    // Load booking statistics and provider profile
    _loadBookingStatistics();
    _loadProviderProfile();
    
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
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
            ? const Color(0xFF34C759) 
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
          backgroundColor: const Color(0xFF34C759),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: CustomScrollView(
                slivers: [
                  // Custom App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    elevation: 0,
                    systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                          letterSpacing: -0.5,
                        ),
                        child: Text(l10n.dashboard),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark 
                              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                              : [Colors.white, const Color(0xFFF2F2F7)],
                          ),
                        ),
                      ),
                    ),
        actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            // Auto-refresh indicator
                            if (_isAutoRefreshActive)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.5, end: 1.0),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: child,
                                    );
                                  },
                                  onEnd: () {
                                    if (mounted && _isAutoRefreshActive) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            GestureDetector(
                              onTap: _refreshData,
                              onLongPress: () {
                                setState(() {
                                  _isAutoRefreshActive = !_isAutoRefreshActive;
                                });
                                if (_isAutoRefreshActive) {
                                  _startAutoRefresh();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.autoRefreshEnabled),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  _stopAutoRefresh();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.autoRefreshDisabled),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Icon(
                                Icons.refresh_rounded,
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.translate,
                          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                          size: 24,
                        ),
                        onPressed: () async {
                          final localeService = Provider.of<LocaleService>(context, listen: false);
                          await localeService.toggleLocale();
                          // Show a snackbar to confirm language change
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.languageChanged,
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                            size: 24,
                          ),
                          onSelected: (value) {
                            if (value == 'logout') {
                              _showLogoutDialog(context, authService);
                            } else if (value == 'delete') {
                              _showDeleteAccountDialog(context, authService);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  const Icon(Icons.logout_rounded, size: 20),
                                  const SizedBox(width: 12),
                                  Text(l10n.signOut),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text(l10n.deleteAccount, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Welcome Section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isProviderAvailable 
                                      ? [const Color(0xFF007AFF), const Color(0xFF5856D6)]
                                      : [const Color(0xFF8E8E93), const Color(0xFF6D6D70)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _isProviderAvailable ? Icons.person_rounded : Icons.person_off_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.welcomeBack,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isProviderAvailable ? l10n.readyToServe : l10n.currentlyUnavailable,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: _isProviderAvailable 
                                          ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
                                          : (isDark ? Colors.white54 : const Color(0xFF8E8E93)),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Availability Toggle Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isProviderAvailable 
                                ? const Color(0xFF34C759).withOpacity(0.1)
                                : const Color(0xFFFF9500).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isProviderAvailable 
                                  ? const Color(0xFF34C759).withOpacity(0.3)
                                  : const Color(0xFFFF9500).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _isProviderAvailable 
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFFF9500),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isProviderAvailable 
                                      ? Icons.check_circle
                                      : Icons.pause_circle_filled,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.availabilityStatus,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isProviderAvailable 
                                          ? l10n.availableForBookings
                                          : l10n.currentlyUnavailable,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Toggle Switch
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: _isProviderAvailable,
                                    onChanged: _isUpdatingAvailability 
                                      ? null 
                                      : (value) => _updateProviderAvailability(value),
                                    activeColor: const Color(0xFF34C759),
                                    inactiveThumbColor: const Color(0xFFFF9500),
                                    inactiveTrackColor: const Color(0xFFFF9500).withOpacity(0.3),
                                  ),
                                ),
                                if (_isUpdatingAvailability)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick Stats
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              l10n.pending,
                                                              l10n.bookings,
                              Icons.schedule_rounded,
                              const Color(0xFF34C759),
                              isDark,
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
                              const Color(0xFF007AFF),
                              isDark,
                              _isLoadingStats ? '...' : _completedThisMonth.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Cards
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildActionCard(
                            context,
                            l10n.manageProfile,
                                                          l10n.updateServicesRates,
                            Icons.person_outline_rounded,
                            const Color(0xFF007AFF),
                            () => _navigateToProfile(context),
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            context,
                            l10n.manageBookings,
                                                          l10n.viewRespondBookings,
                            Icons.calendar_today_rounded,
                            const Color(0xFF34C759),
                            () => _navigateToBookings(context),
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            context,
                            l10n.messages,
                                                          l10n.viewRespondMessages,
                            Icons.chat_bubble_outline_rounded,
                            const Color(0xFFFF9500),
                            () => _navigateToMessages(context),
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            ),
          ),
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
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1D1D1F),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
              width: 1,
            ),
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
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                size: 24,
              ),
            ],
          ),
        ),
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
                  color: Color(0xFF007AFF),
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
                        style: const TextStyle(
                          color: Colors.red,
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
                  color: Color(0xFF007AFF),
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
