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
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/conversation_service.dart';
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
  final Map<String, String> _providerToBookingId = {};
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
        
        // Map providerId -> most recent bookingId (bookings are typically newest first)
        final providerToBooking = <String, String>{};
        for (final booking in bookings) {
          final pid = booking.provider?.id;
          if (pid != null && !providerToBooking.containsKey(pid)) {
            providerToBooking[pid] = booking.id;
          }
        }
        final providerIds = providerToBooking.keys.take(5).toList();
        
        print('🔍 DEBUG: Provider IDs found: $providerIds');
        
        // Fetch provider details for recent providers
        List<Provider> providers = [];
        final providerBookingMap = <String, String>{};
        for (String providerId in providerIds) {
          try {
            final p = await _apiService.fetchProviderById(providerId, token);
            if (p != null) {
              providers.add(p);
              providerBookingMap[providerId] = providerToBooking[providerId]!;
            }
          } catch (e) {
            print('Error fetching provider $providerId: $e');
          }
        }
        
        setState(() {
          _recentProviders = providers;
          _providerToBookingId.clear();
          _providerToBookingId.addAll(providerBookingMap);
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

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final trimmed = fullName.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.length >= 2 ? trimmed.substring(0, 2).toUpperCase() : trimmed[0].toUpperCase();
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
                _buildRecentProviders(l10n, isDark),
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
          l10n.welcomeBack,
          style: TextStyle(
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
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
    return _buildSearchPrompt(l10n, isDark);
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

  Widget _buildSearchPrompt(AppLocalizations l10n, bool isDark) {
    return GestureDetector(
      onTap: () => _onTabTapped(1),
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
              Icons.search_rounded,
              color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.4),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.findServices,
                    style: TextStyle(
                      color: isDark ? AppTheme.white : AppTheme.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    l10n.browseProviders,
                    style: TextStyle(
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.viewAll,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
            Icons.history_outlined,
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
                        final bookingId = provider.id != null
                            ? _providerToBookingId[provider.id!]
                            : null;
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildProviderCard(provider, isDark, bookingId),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProviderCardImage(Provider provider, bool isDark) {
    final hasImage = provider.profilePictureUrl != null &&
        provider.profilePictureUrl!.trim().isNotEmpty;
    final imageUrl = hasImage && !provider.profilePictureUrl!.startsWith('http')
        ? '${ConversationService.baseImageUrl}/${provider.profilePictureUrl!.replaceFirst(RegExp(r'^/'), '')}'
        : provider.profilePictureUrl;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: hasImage && imageUrl != null
            ? ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildProviderPlaceholder(provider, isDark),
                ),
              )
            : _buildProviderPlaceholder(provider, isDark),
      ),
    );
  }

  Widget _buildProviderPlaceholder(Provider provider, bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(provider.fullName),
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(Provider provider, bool isDark, [String? bookingId]) {
    final canTap = (bookingId != null && bookingId.isNotEmpty) ||
        (provider.id != null && provider.id!.isNotEmpty);
    return GestureDetector(
      onTap: canTap
          ? () {
              if (bookingId != null && bookingId.isNotEmpty) {
                Navigator.of(context).pushNamed(
                  BookingDetailScreen.routeName,
                  arguments: bookingId,
                );
              } else if (provider.id != null) {
                Navigator.of(context).pushNamed(
                  ProviderDetailScreen.routeName,
                  arguments: provider.id!,
                );
              }
            }
          : null,
      child: Container(
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
          _buildProviderCardImage(provider, isDark),
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
                      Icons.star_outline_rounded,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.systemGray,
              elevation: 0,
              iconSize: 24,
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
