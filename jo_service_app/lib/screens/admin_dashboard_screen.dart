import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart';
import '../l10n/app_localizations.dart';
import './user_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add for admin token

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Provider> _allProviders = [];
  List<Provider> _pendingProviders = [];
  List<Provider> _verifiedProviders = [];
  List<Provider> _rejectedProviders = [];
  
  bool _isLoading = true;
  String? _error;
  String? _adminToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      _loadProviders();
    } else {
      // No admin token, redirect to login
      Navigator.of(context).pushReplacementNamed('/admin-login');
    }
  }

  Future<void> _loadProviders() async {
    if (_adminToken == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load providers from real backend API
      final response = await _apiService.getProvidersForAdmin(_adminToken!);
      final providersData = response['providers'] as List;
      
      _allProviders = providersData.map((data) => Provider.fromJson(data)).toList();
      _filterProviders();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      // If token is invalid, redirect to login
      if (e.toString().contains('token') || e.toString().contains('auth')) {
        Navigator.of(context).pushReplacementNamed('/admin-login');
      }
    }
  }

  void _filterProviders() {
    _pendingProviders = _allProviders.where((p) => (p.verificationStatus ?? 'pending') == 'pending').toList();
    _verifiedProviders = _allProviders.where((p) => (p.verificationStatus ?? 'pending') == 'verified').toList();
    _rejectedProviders = _allProviders.where((p) => (p.verificationStatus ?? 'pending') == 'rejected').toList();
  }

  Future<void> _updateProviderStatus(String providerId, String newStatus) async {
    if (_adminToken == null || providerId.isEmpty) return;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Call real backend API to update status
      await _apiService.updateProviderStatus(_adminToken!, providerId, newStatus);

      // Update local data
      final providerIndex = _allProviders.indexWhere((p) => p.id == providerId);
      if (providerIndex != -1) {
        _allProviders[providerIndex] = _allProviders[providerIndex].copyWith(
          verificationStatus: newStatus,
        );
        _filterProviders();
      }

      Navigator.of(context).pop(); // Close loading dialog

      setState(() {});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.providerStatusUpdatedTo} $newStatus'),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Add haptic feedback
      HapticFeedback.lightImpact();

    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating provider: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showProviderDetails(Provider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProviderDetailSheet(provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.logout,
            color: isDark ? Colors.white : const Color(0xFF000000),
            size: 20,
          ),
          onPressed: () async {
            // Clear admin token on logout
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('admin_token');
            await prefs.remove('admin_email');
            
            Navigator.of(context).pushReplacementNamed(UserLoginScreen.routeName);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
            Text(
              'Provider Management',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.book_online,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
            onPressed: () {
              // Navigate to booking management screen
              Navigator.of(context).pushNamed('/admin-bookings');
            },
            tooltip: 'Booking Management',
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
            onPressed: () {
              // Navigate to create provider screen
              Navigator.of(context).pushNamed('/admin/create-provider').then((_) {
                // Refresh providers list after creating
                _loadProviders();
              });
            },
            tooltip: 'Create Provider',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
            onPressed: _loadProviders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF007AFF),
          unselectedLabelColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF007AFF),
          tabs: [
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
                      '${_allProviders.length}',
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
                      '${_pendingProviders.length}',
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
                  const Text('Verified'),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_verifiedProviders.length}',
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
                  const Text('Rejected'),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_rejectedProviders.length}',
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
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: const Color(0xFFFF3B30),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading providers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!.replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF8E8E93) 
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProviders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProviderList(_allProviders),
                    _buildProviderList(_pendingProviders),
                    _buildProviderList(_verifiedProviders),
                    _buildProviderList(_rejectedProviders),
                  ],
                ),
    );
  }

  Widget _buildProviderList(List<Provider> providers) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF8E8E93) 
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            Text(
              'No providers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF8E8E93) 
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        return _buildProviderCard(providers[index]);
      },
    );
  }

  Widget _buildProviderCard(Provider provider) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String status = provider.verificationStatus ?? 'pending';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'verified':
        statusColor = const Color(0xFF34C759);
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = const Color(0xFFFF9500);
        statusIcon = Icons.access_time;
        break;
      case 'rejected':
        statusColor = const Color(0xFFFF3B30);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFF8E8E93);
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showProviderDetails(provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: statusColor.withOpacity(0.1),
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
                            provider.fullName ?? 'Unknown Provider',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF000000),
                            ),
                          ),
                          Text(
                            provider.serviceType ?? '',
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Details
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.location?.city ?? 'Unknown Location',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    ),
                    Text(
                      '${provider.hourlyRate?.toStringAsFixed(0) ?? '0'} JOD/hr',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                
                // Action Buttons - Show different options based on current status
                const SizedBox(height: 12),
                if (status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateProviderStatus(provider.id ?? '', 'verified'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text(
                            'Verify',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateProviderStatus(provider.id ?? '', 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF3B30),
                            side: const BorderSide(color: Color(0xFFFF3B30)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text(
                            'Reject',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'verified') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateProviderStatus(provider.id ?? '', 'pending'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007AFF),
                            side: const BorderSide(color: Color(0xFF007AFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.pending, size: 16),
                          label: const Text(
                            'Set Pending',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateProviderStatus(provider.id ?? '', 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF3B30),
                            side: const BorderSide(color: Color(0xFFFF3B30)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text(
                            'Suspend',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'rejected') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateProviderStatus(provider.id ?? '', 'verified'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text(
                            'Re-verify',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateProviderStatus(provider.id ?? '', 'pending'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007AFF),
                            side: const BorderSide(color: Color(0xFF007AFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text(
                            'Review Again',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderDetailSheet(Provider provider) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String status = provider.verificationStatus ?? 'pending';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Provider Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF000000),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: const Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Full Name', provider.fullName ?? 'N/A'),
                  _buildDetailRow('Company', provider.companyName ?? 'N/A'),
                  _buildDetailRow('Email', provider.email ?? 'N/A'),
                  _buildDetailRow('Phone', provider.contactInfo?.phone ?? 'N/A'),
                  _buildDetailRow('Service Type', provider.serviceType ?? 'N/A'),
                  _buildDetailRow('Hourly Rate', '${provider.hourlyRate?.toStringAsFixed(0) ?? '0'} JOD'),
                  _buildDetailRow('Location', provider.location?.addressText ?? 'N/A'),
                  _buildDetailRow('Status', status.toUpperCase()),
                  _buildDetailRow('Rating', '${provider.rating?.toStringAsFixed(1) ?? '0.0'} ⭐'),
                  _buildDetailRow('Completed Jobs', '${provider.completedJobs ?? 0}'),
                  _buildDetailRow('Joined', provider.joinedDate?.toString().split(' ')[0] ?? 'N/A'),
                  
                  // Action Buttons - Bidirectional status changes
                  const SizedBox(height: 24),
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateProviderStatus(provider.id ?? '', 'verified');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34C759),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.verified),
                            label: const Text(
                              'Verify Provider',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateProviderStatus(provider.id ?? '', 'rejected');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF3B30),
                              side: const BorderSide(color: Color(0xFFFF3B30)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.cancel),
                            label: const Text(
                              'Reject Provider',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'verified') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateProviderStatus(provider.id ?? '', 'pending');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF007AFF),
                              side: const BorderSide(color: Color(0xFF007AFF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.pending),
                            label: const Text(
                              'Set as Pending',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateProviderStatus(provider.id ?? '', 'rejected');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF3B30),
                              side: const BorderSide(color: Color(0xFFFF3B30)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.block),
                            label: const Text(
                              'Suspend Provider',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'rejected') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateProviderStatus(provider.id ?? '', 'verified');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34C759),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.verified_user),
                            label: const Text(
                              'Re-verify Provider',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _updateProviderStatus(provider.id ?? '', 'pending');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF007AFF),
                              side: const BorderSide(color: Color(0xFF007AFF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text(
                              'Review Again',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 