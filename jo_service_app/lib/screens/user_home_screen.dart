import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../l10n/app_localizations.dart';
import '../models/provider_model.dart';
import '../models/booking_model.dart';
import '../constants/theme.dart';
import 'provider_list_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
import 'user_chats_screen.dart';
import '../services/api_service.dart';
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
  late Future<List<Provider>> _providersFuture;
  final PageController _pageController = PageController();
  
  // API service instances
  final ApiService _apiService = ApiService();
  final BookingService _bookingService = BookingService();
  
  // Real data state variables
  List<Provider> _recentProviders = [];
  int _activeBookingsCount = 0;
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
        _loadRecentProviders(),
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
  
  Future<void> _loadRecentProviders() async {
    try {
      final authService = provider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      print('🔍 DEBUG: Loading recent providers...');
      print('🔍 DEBUG: Token exists: ${token != null}');
      
      if (token != null) {
        // Get user's recent bookings to find recent providers
        final response = await _bookingService.getUserBookings(token: token, limit: 10);
        print('🔍 DEBUG: Bookings response: $response');
        
        final bookingsData = response['bookings'] as List<dynamic>? ?? [];
        print('🔍 DEBUG: Bookings data count: ${bookingsData.length}');
        
        // The bookings are already parsed as Booking objects, no need to call fromJson
        final bookings = bookingsData.cast<Booking>();
        print('🔍 DEBUG: Parsed bookings count: ${bookings.length}');
        
        // Extract unique providers from recent bookings
        final providerIds = bookings
            .where((booking) => booking.provider?.id != null)
            .map((booking) => booking.provider!.id!)
            .toSet()
            .toList();
        
        print('🔍 DEBUG: Provider IDs found: $providerIds');
        
        // Fetch provider details for recent providers
        List<Provider> providers = [];
        for (String providerId in providerIds.take(5)) {
          try {
            final provider = await _apiService.fetchProviderById(providerId, token);
            if (provider != null) {
              providers.add(provider);
            }
          } catch (e) {
            print('Error fetching provider $providerId: $e');
          }
        }
        
        setState(() {
          _recentProviders = providers;
        });
      }
    } catch (e) {
      print('Error loading recent providers: $e');
      // Fallback to all providers if recent providers fail
      _providersFuture = _getAllProviders();
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
        
        print('📊 DEBUG: Active bookings count: $activeBookings');
        
        setState(() {
          _activeBookingsCount = activeBookings;
        });
      }
    } catch (e) {
      print('Error loading user activity: $e');
    }
  }
  
  Future<List<Provider>> _getAllProviders() async {
    try {
      final authService = provider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      if (token != null) {
        final response = await _apiService.fetchProviders(null);
        return response.providers;
      }
    } catch (e) {
      print('Error loading providers: $e');
    }
    return [];
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
            _buildHomeTab(),
            const ProviderListScreen(),
            const UserBookingsScreen(),
            const UserProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isDark),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: isDark ? AppTheme.dark : AppTheme.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_rounded),
                color: Colors.white, // Always white for better visibility on gradient background
                onPressed: () {
                  // Navigate to user chats screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserChatsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
                                  l10n.jordanServiceProvider,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.secondary,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Welcome Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(isDark),
                const SizedBox(height: 24),
                _buildQuickActions(isDark),
                const SizedBox(height: 24),
                _buildRecentProviders(l10n, isDark),
                const SizedBox(height: 24),
                _buildStatsCard(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: AppTheme.white,
              size: 30,
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
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                                      l10n.findPerfectService,
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                              l10n.quickActions,
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search_rounded,
                title: l10n.findServices,
                subtitle: l10n.browseProviders,
                color: AppTheme.primary,
                isDark: isDark,
                onTap: () => _onTabTapped(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_today_rounded,
                title: l10n.myBookings,
                subtitle: l10n.viewAppointments,
                color: AppTheme.accent,
                isDark: isDark,
                onTap: () => _onTabTapped(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.favorite_rounded,
                title: l10n.favorites,
                subtitle: l10n.savedProviders,
                color: AppTheme.warning,
                isDark: isDark,
                onTap: () => _onTabTapped(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_rounded,
                title: l10n.profile,
                subtitle: l10n.manageAccount,
                color: AppTheme.secondary,
                isDark: isDark,
                onTap: () => _onTabTapped(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProviders(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentProviders,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _onTabTapped(1),
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
          height: 200,
          child: _isLoadingActivity
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                )
              : _recentProviders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No recent providers yet',
                            style: TextStyle(
                              color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Book a service to see recent providers here',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentProviders.length,
                      itemBuilder: (context, index) {
                        final provider = _recentProviders[index];
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildProviderCard(provider, isDark),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Provider provider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.business_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.fullName ?? 'Unknown',
                  style: TextStyle(
                    color: isDark ? AppTheme.white : AppTheme.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getLocalizedServiceType(provider.serviceType, AppLocalizations.of(context)!),
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.averageRating?.toStringAsFixed(1) ?? '4.5'}',
                      style: TextStyle(
                        color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    icon: Icons.calendar_today_rounded,
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
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.dark : AppTheme.white,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.systemGray,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: AppLocalizations.of(context)!.services,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: AppLocalizations.of(context)!.bookings,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
