import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../models/provider_model.dart';
import '../models/booking_model.dart';
import '../constants/theme.dart';
import 'provider_list_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
import 'user_chats_screen.dart';
import 'booking_detail_screen.dart';
import 'provider_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import 'package:provider/provider.dart' as provider; // Import provider package

class UserHomeScreen extends StatefulWidget {
  static const routeName = '/user-home';
  
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  final BookingService _bookingService = BookingService();
  
  // Real data state variables
  List<Booking> _recentBookings = [];
  int _activeBookingsCount = 0;
  Booking? _nextUpcomingBooking;
  bool _isLoadingActivity = false;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }
  
  Future<void> _loadRealData() async {
    setState(() {
      _isLoadingActivity = true;
    });
    
    try {
      // Load recent providers and user activity data
      await Future.wait([
        _loadUserActivity(),
      ]);
    } catch (e) {
      print('Error loading real data: $e');
    } finally {
      setState(() {
        _isLoadingActivity = false;
      });
    }
  }
  
  Future<void> _loadUserActivity() async {
    try {
      final authService = provider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      print('📊 DEBUG: Loading user activity...');
      
      if (token != null) {
        final response = await _bookingService.getUserBookings(token: token);
        print('📊 DEBUG: Activity response: $response');
        
        final bookingsData = response['bookings'] as List<dynamic>? ?? [];
        // The bookings are already parsed as Booking objects, no need to call fromJson
        final bookings = bookingsData.cast<Booking>();
        
        print('📊 DEBUG: Total bookings for activity: ${bookings.length}');
        
        // Print all booking statuses for debugging
        for (var booking in bookings) {
          print('📊 DEBUG: Booking status: ${booking.status}');
        }
        
        // Count active bookings (pending, accepted, in_progress)
        final activeBookings = bookings.where((booking) => 
          booking.status == 'pending' || 
          booking.status == 'accepted' || 
          booking.status == 'in_progress'
        ).length;
        
        // Next upcoming booking (future date, active status)
        final now = DateTime.now();
        final upcoming = bookings
            .where((b) => (b.status == 'pending' || b.status == 'accepted' || b.status == 'in_progress') && 
                b.serviceDateTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.serviceDateTime.compareTo(b.serviceDateTime));
        
        print('📊 DEBUG: Active bookings count: $activeBookings');
        
        setState(() {
          _activeBookingsCount = activeBookings;
          _nextUpcomingBooking = upcoming.isNotEmpty ? upcoming.first : null;
          _recentBookings = bookings.take(8).toList();
        });
      }
    } catch (e) {
      print('Error loading user activity: $e');
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper function to translate service types
  String _getLocalizedServiceType(String? serviceType, AppLocalizations l10n) {
    if (serviceType == null) return l10n.unknown;
    
    switch (serviceType.toLowerCase()) {
      case 'electrician':
        return l10n.electrician;
      case 'plumber':
        return l10n.plumber;
      case 'painter':
        return l10n.painter;
      case 'cleaner':
        return l10n.cleaner;
      case 'carpenter':
        return l10n.carpenter;
      case 'gardener':
        return l10n.gardener;
      case 'mechanic':
        return l10n.mechanic;
      case 'air conditioning technician':
      case 'airconditioning':
        return l10n.airConditioningTechnician;
      case 'general maintenance':
      case 'maintenance':
        return l10n.generalMaintenance;
      case 'housekeeper':
        return l10n.housekeeper;
      default:
        return serviceType; // Return original if no translation found
    }
  }

  IconData _getServiceIcon(String? serviceType) {
    if (serviceType == null) return Icons.home_repair_service_outlined;
    switch (serviceType.toLowerCase()) {
      case 'plumber':
      case 'plumbing':
        return Icons.plumbing;
      case 'electrician':
      case 'electrical':
        return Icons.electrical_services;
      case 'painter':
      case 'painting':
        return Icons.format_paint;
      case 'cleaner':
      case 'cleaning':
        return Icons.cleaning_services;
      case 'carpenter':
      case 'carpentry':
        return Icons.handyman;
      case 'gardener':
      case 'gardening':
        return Icons.yard;
      case 'mechanic':
        return Icons.build;
      case 'air conditioning technician':
      case 'airconditioning':
        return Icons.ac_unit;
      case 'general maintenance':
      case 'maintenance':
        return Icons.home_repair_service_outlined;
      case 'housekeeper':
        return Icons.cleaning_services;
      default:
        return Icons.home_repair_service_outlined;
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        if (_currentIndex != 0) {
          // If not on home tab, go back to home
          setState(() {
            _currentIndex = 0;
          });
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false; // Don't pop the route
        }
        // If on home tab, navigate to role selection instead of allowing back navigation
        // This prevents the black screen issue when there's no previous route
        Navigator.of(context).pushReplacementNamed('/');
        return false; // Don't pop the route, we're handling navigation manually
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.dark : AppTheme.light,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            Navigator(
              onGenerateRoute: _generateTabRoute,
              initialRoute: '/home',
            ),
            Navigator(
              onGenerateRoute: _generateTabRoute,
              initialRoute: '/services',
            ),
            Navigator(
              onGenerateRoute: _generateTabRoute,
              initialRoute: '/bookings',
            ),
            Navigator(
              onGenerateRoute: _generateTabRoute,
              initialRoute: '/profile',
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isDark),
      ),
    );
  }

  Route<dynamic>? _generateTabRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => _buildHomeTab());
      case '/services':
        return MaterialPageRoute(builder: (_) => const ProviderListScreen());
      case '/bookings':
        return MaterialPageRoute(builder: (_) => const UserBookingsScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case ProviderDetailScreen.routeName:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(providerId: id),
        );
      case BookingDetailScreen.routeName:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: id),
        );
      default:
        return MaterialPageRoute(builder: (_) => _buildHomeTab());
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _loadRealData();
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildHomeTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomScrollView(
      slivers: [
        // Clean minimal header (white, no gradient)
        SliverToBoxAdapter(
          child: Container(
            color: isDark ? AppTheme.dark : AppTheme.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/jo_logo.svg',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.appTitle,
                          style: TextStyle(
                            color: isDark ? AppTheme.white : AppTheme.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.appBrandSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isDark ? AppTheme.white : Colors.black87,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserChatsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Main content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildWelcomeCard(isDark),
                const SizedBox(height: 32),
                _buildHighValueContent(l10n, isDark),
                const SizedBox(height: 32),
                _buildCases(l10n, isDark),
                const SizedBox(height: 24),
                _buildStatsCard(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.findPerfectService,
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHighValueContent(AppLocalizations l10n, bool isDark) {
    if (_nextUpcomingBooking != null) {
      return _buildNextAppointmentCard(l10n, isDark);
    }
    return _buildMostUsedServices(l10n, isDark);
  }

  Widget _buildNextAppointmentCard(AppLocalizations l10n, bool isDark) {
    final b = _nextUpcomingBooking!;
    final providerName = b.provider?.fullName ?? l10n.provider;
    final serviceType = _getLocalizedServiceType(b.provider?.serviceType, l10n);
    final formattedDate = '${b.serviceDateTime.day}/${b.serviceDateTime.month}/${b.serviceDateTime.year}';
    final formattedTime = '${b.serviceDateTime.hour.toString().padLeft(2, '0')}:${b.serviceDateTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          BookingDetailScreen.routeName,
          arguments: b.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.upcomingBookings,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    providerName,
                    style: TextStyle(
                      color: isDark ? AppTheme.white : AppTheme.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$serviceType · $formattedDate $formattedTime',
                    style: TextStyle(
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Two most-used services plus "More" button. Tapping a service opens provider list filtered by that type.
  Widget _buildMostUsedServices(AppLocalizations l10n, bool isDark) {
    final mostUsed = [
      {'category': 'Plumbing', 'displayName': l10n.plumbing, 'icon': Icons.plumbing},
      {'category': 'Electrical', 'displayName': l10n.electrical, 'icon': Icons.electrical_services},
    ];
    return Row(
      children: [
        for (final service in mostUsed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildServiceCard(
                displayName: service['displayName'] as String,
                icon: service['icon'] as IconData,
                category: service['category'] as String,
                isDark: isDark,
              ),
            ),
          ),
        _buildMoreButton(l10n, isDark),
      ],
    );
  }

  Widget _buildServiceCard({
    required String displayName,
    required IconData icon,
    required String category,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _openProviderListForCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton(AppLocalizations l10n, bool isDark) {
    return GestureDetector(
      onTap: () => _onTabTapped(1),
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              l10n.more,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProviderListForCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderListScreen(initialCategory: category),
      ),
    );
  }

  static bool _isCaseDone(String status) {
    return status == 'completed' || status == 'paid' ||
        status == 'declined_by_provider' || status == 'cancelled_by_user';
  }

  Widget _buildCases(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.cases,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => _onTabTapped(2),
              child: Text(
                l10n.seeAll,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: _isLoadingActivity
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                )
              : _recentBookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 48,
                            color: AppTheme.systemGray,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noCasesYet,
                            style: TextStyle(
                              color: AppTheme.systemGray,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.bookServiceToSeeCases,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.systemGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentBookings.length,
                      itemBuilder: (context, index) {
                        final booking = _recentBookings[index];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildCaseCard(booking, l10n, isDark),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCaseCard(Booking booking, AppLocalizations l10n, bool isDark) {
    final isDone = _isCaseDone(booking.status);
    final providerName = booking.provider?.fullName ?? l10n.provider;
    final serviceType = _getLocalizedServiceType(booking.provider?.serviceType, l10n);
    final dateStr = '${booking.serviceDateTime.day}/${booking.serviceDateTime.month}/${booking.serviceDateTime.year}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          BookingDetailScreen.routeName,
          arguments: booking.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? const Color(0xFF34C759).withOpacity(0.25)
                : AppTheme.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF34C759).withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    size: 22,
                    color: isDone ? const Color(0xFF34C759) : AppTheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF34C759).withOpacity(0.12)
                        : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDone ? l10n.done : l10n.pending,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDone ? const Color(0xFF34C759) : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              providerName,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              serviceType,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                color: AppTheme.systemGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.yourActivity,
            style: TextStyle(
              color: isDark ? AppTheme.white : AppTheme.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: _isLoadingActivity
                ? const CircularProgressIndicator(
                    color: AppTheme.primary,
                  )
                : _buildStatItem(
                    icon: Icons.calendar_today_outlined,
                    value: _activeBookingsCount.toString(),
                    label: AppLocalizations.of(context)!.activeBookings,
                    color: AppTheme.primary,
                    isDark: isDark,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
Icon(
        icon,
        color: color,
        size: 28,
      ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        border: Border(
          top: BorderSide(
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: isDark ? AppTheme.dark : AppTheme.white,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.systemGray,
              elevation: 0,
              iconSize: 22,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(_currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined),
                  label: l10n.home,
                ),
BottomNavigationBarItem(
                icon: Icon(_currentIndex == 1 ? Icons.search_rounded : Icons.search_rounded),
                label: l10n.navServices,
              ),
                BottomNavigationBarItem(
                  icon: Icon(_currentIndex == 2 ? Icons.calendar_month_rounded : Icons.calendar_month_outlined),
                  label: l10n.bookings,
                ),
                BottomNavigationBarItem(
                  icon: Icon(_currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded),
                  label: l10n.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
