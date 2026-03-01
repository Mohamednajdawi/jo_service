import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/service_type_localizer.dart';
import './booking_detail_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  static const routeName = '/user-bookings';

  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  bool _isLoading = false;
  List<Booking> _bookings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  final ScrollController _scrollController = ScrollController();

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

  // Tab labels for better UI display - moved to build method for l10n support

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_scrollListener);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
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
      final userId = await authService.getUserId();

      if (token == null || userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.authenticationError)),
          );
        return;
      }

      // First try the regular endpoint
      try {
        final result = await _bookingService.getUserBookings(
          token: token,
          status: _statusFilters[_tabController.index],
          page: _currentPage,
        );

        final bookings = result['bookings'] as List<Booking>;

        if (mounted) {
          setState(() {
            _bookings = bookings;
            _currentPage = result['currentPage'] as int;
            _totalPages = result['totalPages'] as int;
            _hasMorePages = _currentPage < _totalPages;
            _isLoading = false;
          });
        }
      } catch (e) {
        // If regular endpoint fails, try the direct method
        final bookings = await _bookingService.getBookingsByUserId(
          token: token,
          userId: userId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingBookings}: $e')),
        );
      }
    }
  }

  // Load more bookings when scrolling to the bottom
  Future<void> _loadMoreBookings() async {
    if (_isLoading || !_hasMorePages) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final userId = await authService.getUserId();

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.authenticationError)),
        );
        return;
      }

      try {
        final result = await _bookingService.getUserBookings(
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
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingMoreBookings}: $e')),
        );
      }
    }
  }

  // Handle booking cancellation
  Future<void> _cancelBooking(Booking booking) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.authenticationError)),
        );
        return;
      }

      await _bookingService.updateBookingStatus(
        token: token,
        bookingId: booking.id,
        status: 'cancelled_by_user',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.bookingCancelled)),
      );

      // Refresh the list
      _fetchBookings();
    } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.errorCancellingBooking}: $e')),
          );
    }
  }

  // Confirm cancellation dialog
  void _showCancellationDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.cancelBooking),
          content: Text(AppLocalizations.of(context)!.areYouSureCancelBooking),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelBooking(booking);
            },
                          child: Text(AppLocalizations.of(context)!.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Tab labels with localization support
    final List<String> tabLabels = [
      l10n.all,
      l10n.pending,
      l10n.accepted,
      l10n.inProgress,
      l10n.completed,
      l10n.declined,
      l10n.cancelled,
    ];;
    return Scaffold(
      backgroundColor: AppTheme.light,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.myBookings,
          style: AppTheme.h3.copyWith(color: AppTheme.dark),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.grey,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: AppTheme.h4.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTheme.h4,
                      tabs: tabLabels
              .map((label) => Tab(
                    text: label,
                  ))
              .toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        color: AppTheme.primary,
        child: TabBarView(
          controller: _tabController,
          children: _statusFilters.map((status) {
            return _buildBookingsList(l10n);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingsList(AppLocalizations l10n) {
    if (_isLoading && _bookings.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppTheme.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noBookingsFound,
              style: AppTheme.h3.copyWith(color: AppTheme.dark),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scheduleNewService,
              style: AppTheme.body3.copyWith(color: AppTheme.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _bookings.length) {
          return _buildLoader();
        }
        return _buildBookingCard(_bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    final statusColors = {
      'pending': AppTheme.warning,
      'accepted': AppTheme.primary,
      'in_progress': AppTheme.primary,
      'completed': AppTheme.success,
      'declined_by_provider': AppTheme.danger,
      'cancelled_by_user': AppTheme.grey,
    };

    final statusLabels = {
      'pending': l10n.pending,
      'accepted': l10n.accepted,
      'in_progress': l10n.inProgress,
      'completed': l10n.completed,
      'declined_by_provider': l10n.declined,
      'cancelled_by_user': l10n.cancelled,
    };

    final color = statusColors[booking.status] ?? AppTheme.grey;
    final label = statusLabels[booking.status] ?? l10n.unknownStatus;

    // Format date once
    final formattedDate =
        DateFormat('MMM d, yyyy').format(booking.serviceDateTime);
    final formattedTime = DateFormat('h:mm a').format(booking.serviceDateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            BookingDetailScreen.routeName,
            arguments: booking.id,
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with service type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          radius: 20,
                          child: Icon(
                            _getServiceIcon(booking.provider?.serviceType),
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.provider?.serviceType != null 
                                ? ServiceTypeLocalizer.getLocalizedServiceType(booking.provider!.serviceType!, l10n)
                                : l10n.service,
                            style: AppTheme.h3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: AppTheme.body5.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Provider info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppTheme.grey),
                  const SizedBox(width: 8),
                  Text(
                    booking.provider?.companyName ??
                        booking.provider?.fullName ??
                        l10n.unknownProvider,
                    style: AppTheme.body4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.grey),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: AppTheme.body4,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: AppTheme.grey),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: AppTheme.body4,
                  ),
                ],
              ),

              // Location if available
              if (booking.serviceLocationDetails != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.serviceLocationDetails!,
                        style: AppTheme.body4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Price
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: AppTheme.grey),
                  const SizedBox(width: 8),
                  Text(
                    '\$${booking.provider?.hourlyRate?.toStringAsFixed(2) ?? 'N/A'}',
                    style: AppTheme.body4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),

              // Cancel button if applicable
              if (booking.status == 'pending' ||
                  booking.status == 'accepted') ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showCancellationDialog(booking),
                    icon: Icon(Icons.cancel, color: AppTheme.danger, size: 18),
                    label: Text(
                                                    l10n.cancelBooking,
                      style: TextStyle(color: AppTheme.danger),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String? serviceType) {
    if (serviceType == null) return Icons.home_repair_service;

    switch (serviceType.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'gardening':
        return Icons.yard;
      case 'painting':
        return Icons.format_paint;
      case 'carpentry':
        return Icons.handyman;
      default:
        return Icons.home_repair_service;
    }
  }

  Widget _buildLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}
