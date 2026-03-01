import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/navigation_service.dart';
import './booking_detail_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  static const routeName = '/provider-bookings';

  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  bool _isLoading = false;
  List<Booking> _bookings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Auto-refresh timer
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);
  
  // Previous booking counts for comparison
  int _previousBookingsCount = 0;
  
  // Auto-refresh indicator
  bool _isAutoRefreshActive = true;

  // Define status filters for tabs
  final List<String?> _statusFilters = [
    null, // All bookings
    'pending',
    'accepted',
    'in_progress',
    'completed',
    'declined_by_provider',
    'cancelled_by_user',
  ];

  @override
  void initState() {
    super.initState();
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_scrollListener);
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    _fetchBookings();
    
    // Start auto-refresh timer
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
          _fetchBookings();
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
        _fetchBookings();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
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
                  l10n.newBookingsReceived(newBookingsCount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF34C759),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Handle tab changes to filter bookings by status
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
        _bookings = [];
      });
      _fetchBookings();
    }
  }

  // Implement infinite scrolling
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMorePages) {
        _loadMoreBookings();
      }
    }
  }

  // Fetch bookings with the current filter
  Future<void> _fetchBookings() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final providerId = await authService.getUserId();

      if (token == null || providerId == null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authenticationErrorPleaseLogin)),
        );
        return;
      }

      try {
        final result = await _bookingService.getProviderBookings(
          token: token,
          status: _statusFilters[_tabController.index],
          page: 1,
        );

        final List<Booking> bookings = result['bookings'] as List<Booking>;

        // Check for new bookings
        if (bookings.length > _previousBookingsCount && _previousBookingsCount > 0) {
          _showNewBookingNotification(bookings.length - _previousBookingsCount);
        }

        if (mounted) {
          setState(() {
            _bookings = bookings;
            _currentPage = result['currentPage'] as int;
            _totalPages = result['totalPages'] as int;
            _hasMorePages = _currentPage < _totalPages;
            _isLoading = false;
          });
          
          // Update previous count
          _previousBookingsCount = bookings.length;
        }
      } catch (e) {
        // If regular endpoint fails, try the direct method
        final bookings = await _bookingService.getBookingsByProviderId(
          token: token,
          providerId: providerId,
        );

        if (mounted) {
          setState(() {
            _bookings = bookings;
            _currentPage = 1;
            _totalPages = 1;
            _hasMorePages = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingBookings}: $e')),
        );
      }
    }
  }

  // Load more bookings when scrolling to the bottom
  Future<void> _loadMoreBookings() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final providerId = await authService.getUserId();

      if (token == null || providerId == null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authenticationErrorPleaseLogin)),
        );
        return;
      }

      try {
        final result = await _bookingService.getProviderBookings(
          token: token,
          status: _statusFilters[_tabController.index],
          page: _currentPage + 1,
        );

        final List<Booking> newBookings = result['bookings'] as List<Booking>;

        if (mounted) {
          setState(() {
            _bookings.addAll(newBookings);
            _currentPage = result['currentPage'] as int;
            _totalPages = result['totalPages'] as int;
            _hasMorePages = _currentPage < _totalPages;
            _isLoading = false;
          });
        }
      } catch (e) {
        // If pagination fails, don't add more bookings
        if (mounted) {
          setState(() {
            _hasMorePages = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoadingBookings}: $e')),
        );
      }
    }
  }

  // Open navigation to user's location
  Future<void> _openNavigation(String address) async {
    try {
      await NavigationService.openGoogleMapsNavigation(
        latitude: 31.9539, // Default to Amman coordinates
        longitude: 35.9106,
        address: address,
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToOpenNavigation}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update booking status (accept, decline, etc.)
  Future<void> _updateBookingStatus(Booking booking, String newStatus) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authenticationErrorPleaseLogin)),
        );
        return;
      }

      await _bookingService.updateBookingStatus(
        token: token,
        bookingId: booking.id,
        status: newStatus,
      );

      // Refresh the bookings list
      _fetchBookings();

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookingStatusUpdatedTo(newStatus.replaceAll('_', ' '))),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorUpdatingBookingStatus}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            child: Column(
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
                  child: Column(
                    children: [
                      Row(
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
                              l10n.providerBookingsTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // Auto-refresh indicator
                              if (_isAutoRefreshActive)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34C759),
                                    borderRadius: BorderRadius.circular(3),
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
                                onTap: () async {
                                  setState(() {
                                    _currentPage = 1;
                                    _bookings = [];
                                  });
                                  await _fetchBookings();
                                },
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
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Custom Tab Bar
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark 
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: isDark ? const Color(0xFF1D1D1F) : Colors.white,
                          unselectedLabelColor: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            Tab(text: l10n.allBookings),
                            Tab(text: l10n.pendingBookings),
                            Tab(text: l10n.acceptedBookings),
                            Tab(text: l10n.inProgressBookings),
                            Tab(text: l10n.completedBookings),
                            Tab(text: l10n.rejectedBookings),
                            Tab(text: l10n.cancelledBookings),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchBookings,
                    color: const Color(0xFF007AFF),
                    child: _isLoading && _bookings.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF007AFF),
                            ),
                          )
                        : _bookings.isEmpty
                            ? _buildEmptyState(isDark)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: _bookings.length + (_hasMorePages ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index < _bookings.length) {
                                    return _buildBookingCard(_bookings[index], isDark);
                                  } else {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF007AFF),
                                        ),
                                      ),
                                    );
                                  }
                                },
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

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 60,
              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noBookingsFound,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noBookingsMessage,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(booking.status);
    final statusIcon = _getStatusIcon(booking.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
      child: InkWell(
          onTap: () => _navigateToBookingDetail(booking),
          borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.user?.fullName ?? 'Booking #${booking.id.substring(0, 8)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(booking.serviceDateTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        _getLocalizedStatus(booking.status, l10n),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 16),
                if (booking.serviceLocationDetails?.isNotEmpty == true) ...[
              Row(
                children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.serviceLocationDetails ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.directions_rounded,
                          size: 18,
                          color: const Color(0xFF007AFF),
                        ),
                        onPressed: () => _openNavigation(booking.serviceLocationDetails!),
                        tooltip: l10n.openInGoogleMaps,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (booking.userNotes?.isNotEmpty == true) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.userNotes ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Action buttons for pending bookings
                if (booking.status == 'pending') ...[
                  Row(
                  children: [
                      Expanded(
                        child: _buildActionButton(
                          l10n.accept,
                          Icons.check_rounded,
                          const Color(0xFF34C759),
                          () => _updateBookingStatus(booking, 'accepted'),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          l10n.decline,
                          Icons.close_rounded,
                          const Color(0xFFFF3B30),
                          () => _updateBookingStatus(booking, 'declined_by_provider'),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ] else if (booking.status == 'accepted') ...[
                  _buildActionButton(
                    l10n.startService,
                    Icons.play_arrow_rounded,
                    const Color(0xFF007AFF),
                    () => _updateBookingStatus(booking, 'in_progress'),
                    isDark,
                  ),
                ] else if (booking.status == 'in_progress') ...[
                  _buildActionButton(
                    l10n.completeService,
                    Icons.check_circle_rounded,
                    const Color(0xFF34C759),
                    () => _updateBookingStatus(booking, 'completed'),
                    isDark,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9500);
      case 'accepted':
        return const Color(0xFF007AFF);
      case 'in_progress':
        return const Color(0xFF5856D6);
      case 'completed':
        return const Color(0xFF34C759);
      case 'declined_by_provider':
      case 'cancelled_by_user':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'in_progress':
        return Icons.play_circle_outline_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'declined_by_provider':
      case 'cancelled_by_user':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pendingBookings;
      case 'accepted':
        return l10n.acceptedBookings;
      case 'in_progress':
        return l10n.inProgressBookings;
      case 'completed':
        return l10n.completedBookings;
      case 'declined_by_provider':
        return l10n.declinedByProvider;
      case 'cancelled_by_user':
        return l10n.cancelledByUser;
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _navigateToBookingDetail(Booking booking) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BookingDetailScreen(bookingId: booking.id),
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
}
