import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/booking_model.dart';
import '../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminBookingManagementScreen extends StatefulWidget {
  static const routeName = '/admin-bookings';

  const AdminBookingManagementScreen({super.key});

  @override
  State<AdminBookingManagementScreen> createState() => _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState extends State<AdminBookingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Booking> _allBookings = [];
  List<Booking> _pendingBookings = [];
  List<Booking> _acceptedBookings = [];
  List<Booking> _completedBookings = [];
  List<Booking> _cancelledBookings = [];
  List<dynamic> _activityFeed = [];
  Map<String, dynamic> _analytics = {};
  
  bool _isLoading = true;
  bool _isLoadingActivity = false;
  bool _isLoadingAnalytics = false;
  String? _error;
  String? _adminToken;
  
  // Filter options
  String _selectedStatus = 'all';
  String _selectedTimeframe = '30d';
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Overview, All, Pending, Active, Completed, Analytics
    _loadAdminToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    _adminToken = prefs.getString('admin_token');
    
    if (_adminToken != null) {
      _loadBookings();
      _loadActivityFeed();
      _loadAnalytics();
    } else {
      Navigator.of(context).pushReplacementNamed('/admin-login');
    }
  }

  Future<void> _loadBookings() async {
    if (_adminToken == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getBookingsForAdmin(_adminToken!, {
        'page': _currentPage.toString(),
        'limit': _itemsPerPage.toString(),
        'status': _selectedStatus == 'all' ? null : _selectedStatus,
      });
      
      final bookingsData = response['data']['bookings'] as List;
      _allBookings = bookingsData.map((data) => Booking.fromJson(data)).toList();
      _filterBookings();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      if (e.toString().contains('token') || e.toString().contains('auth')) {
        Navigator.of(context).pushReplacementNamed('/admin-login');
      }
    }
  }

  Future<void> _loadActivityFeed() async {
    if (_adminToken == null) return;
    
    setState(() {
      _isLoadingActivity = true;
    });

    try {
      final response = await _apiService.getBookingActivityFeed(_adminToken!, {'limit': '50'});
      _activityFeed = response['data']['activities'] as List;
      
      setState(() {
        _isLoadingActivity = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingActivity = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    if (_adminToken == null) return;
    
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final response = await _apiService.getBookingAnalytics(_adminToken!, {'timeframe': _selectedTimeframe});
      _analytics = response['data'];
      
      setState(() {
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  void _filterBookings() {
    _pendingBookings = _allBookings.where((b) => b.status == 'pending').toList();
    _acceptedBookings = _allBookings.where((b) => b.status == 'accepted' || b.status == 'in_progress').toList();
    _completedBookings = _allBookings.where((b) => b.status == 'completed').toList();
    _cancelledBookings = _allBookings.where((b) => b.status == 'cancelled_by_user' || b.status == 'declined_by_provider').toList();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return '0xFFFF9500';
      case 'accepted':
      case 'in_progress':
        return '0xFF007AFF';
      case 'completed':
        return '0xFF34C759';
      case 'cancelled_by_user':
      case 'declined_by_provider':
        return '0xFFFF3B30';
      default:
        return '0xFF8E8E93';
    }
  }

  Widget _buildBookingCard(Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.provider?.serviceType ?? 'Service',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provider: ${booking.provider?.fullName ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          'User: ${booking.user?.fullName ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(_getStatusColor(booking.status))),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getLocalizedStatus(booking.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Service: ${_formatDateTime(booking.serviceDateTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDateTime(booking.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeedItem(dynamic activity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestamp = DateTime.parse(activity['timestamp']);
    final isRecent = activity['isRecent'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isRecent ? 3 : 1,
      color: isRecent ? const Color(0xFFF0F8FF) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(_getStatusColor(activity['status']))),
          child: Icon(
            _getStatusIcon(activity['status']),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          activity['description'],
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRecent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _formatDateTime(timestamp),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
          ),
        ),
        trailing: isRecent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        onTap: () {
          // Navigate to booking details
          _showBookingDetailsById(activity['id']);
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled_by_user':
        return Icons.cancel;
      case 'declined_by_provider':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  Widget _buildAnalyticsCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E8E93),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Booking Details',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(int.parse(_getStatusColor(booking.status))),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getLocalizedStatus(booking.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Service Information
                        _buildDetailSection('Service Information', [
                          _buildDetailRow('Service Type', booking.provider?.serviceType ?? 'N/A'),
                          _buildDetailRow('Service Date', _formatDateTime(booking.serviceDateTime)),
                          _buildDetailRow('Location', booking.serviceLocationDetails ?? 'Not specified'),
                          if (booking.userNotes?.isNotEmpty == true)
                            _buildDetailRow('User Notes', booking.userNotes!),
                        ]),
                        
                        const SizedBox(height: 20),
                        
                        // Provider Information
                        _buildDetailSection('Provider Information', [
                          _buildDetailRow('Name', booking.provider?.fullName ?? 'N/A'),
                          _buildDetailRow('Email', booking.provider?.email ?? 'N/A'),
                          _buildDetailRow('Business', booking.provider?.companyName ?? 'N/A'),
                          if (booking.provider?.hourlyRate != null)
                            _buildDetailRow('Hourly Rate', '\$${booking.provider!.hourlyRate!.toStringAsFixed(2)}'),
                        ]),
                        
                        const SizedBox(height: 20),
                        
                        // User Information
                        _buildDetailSection('User Information', [
                          _buildDetailRow('Name', booking.user?.fullName ?? 'N/A'),
                          _buildDetailRow('Email', booking.user?.email ?? 'N/A'),
                        ]),
                        
                        const SizedBox(height: 20),
                        
                        // Timeline
                        _buildDetailSection('Timeline', [
                          _buildDetailRow('Created', _formatDateTime(booking.createdAt)),
                          _buildDetailRow('Last Updated', _formatDateTime(booking.updatedAt)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBookingDetailsById(String bookingId) {
    // Find booking by ID and show details
    final booking = _allBookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => _allBookings.first, // Fallback
    );
    _showBookingDetails(booking);
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Booking Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBookings();
              _loadActivityFeed();
              _loadAnalytics();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF007AFF),
          unselectedLabelColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF007AFF),
          isScrollable: true,
          tabs: [
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Overview'),
                  if (!_isLoadingActivity && _activityFeed.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_activityFeed.where((a) => a['isRecent'] == true).length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('All'),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E8E93),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_allBookings.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_pendingBookings.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_acceptedBookings.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Completed'),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_completedBookings.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    _buildOverviewTab(),
                    // All Bookings Tab
                    _buildBookingsListTab(_allBookings),
                    // Pending Tab
                    _buildBookingsListTab(_pendingBookings),
                    // Active Tab
                    _buildBookingsListTab(_acceptedBookings),
                    // Completed Tab
                    _buildBookingsListTab(_completedBookings),
                    // Analytics Tab
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadActivityFeed,
      child: _isLoadingActivity
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
          : _activityFeed.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 64,
                        color: Color(0xFF8E8E93),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No booking activities yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All booking activities will appear here:\n• New booking requests\n• Provider acceptances/rejections\n• User cancellations\n• Service completions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Activity Summary Header
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '📊 Live Booking Activity Feed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monitoring: ${_activityFeed.length} activities • ${_activityFeed.where((a) => a['isRecent'] == true).length} recent',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Activity List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        itemCount: _activityFeed.length,
                        itemBuilder: (context, index) {
                          return _buildActivityFeedItem(_activityFeed[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBookingsListTab(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Color(0xFF8E8E93),
            ),
            SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: _isLoadingAnalytics
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeframe Selector
                  Row(
                    children: [
                      const Text(
                        'Timeframe: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      DropdownButton<String>(
                        value: _selectedTimeframe,
                        items: const [
                          DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
                          DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                          DropdownMenuItem(value: '90d', child: Text('Last 90 days')),
                          DropdownMenuItem(value: '1y', child: Text('Last year')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTimeframe = value;
                            });
                            _loadAnalytics();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Analytics Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildAnalyticsCard(
                        'Total Bookings',
                        '${_allBookings.length}',
                        'All time',
                        Icons.book_online,
                        const Color(0xFF007AFF),
                      ),
                      _buildAnalyticsCard(
                        'Pending',
                        '${_pendingBookings.length}',
                        'Awaiting response',
                        Icons.hourglass_empty,
                        const Color(0xFFFF9500),
                      ),
                      _buildAnalyticsCard(
                        'Completed',
                        '${_completedBookings.length}',
                        'Successfully finished',
                        Icons.check_circle,
                        const Color(0xFF34C759),
                      ),
                      _buildAnalyticsCard(
                        'Cancelled',
                        '${_cancelledBookings.length}',
                        'Cancelled or declined',
                        Icons.cancel,
                        const Color(0xFFFF3B30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
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
}
