import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import './provider_signup_screen.dart';
import './user_login_screen.dart';
import './provider_detail_screen.dart';
import './advanced_search_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/service_type_localizer.dart';
import 'dart:convert';

class ProviderListScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialLocation;

  const ProviderListScreen(
      {this.initialSearch, this.initialLocation, super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  late Future<ProviderListResponse> _providersFuture;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProviders = 0;
  final int _limit = 10;
  bool _isLoadingPage = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLocation = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  double _minRating = 0.0;
  double _maxPrice = 1000.0;
  double _maxDistance = 50.0;
  bool _onlyAvailable = false;
  List<String> _selectedTags = [];
  String _sortBy = 'rating';
  String _sortOrder = 'desc';

  List<Map<String, dynamic>> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'name': 'All',
        'displayName': l10n.all,
        'icon': Icons.grid_view_rounded,
      },
      {
        'name': 'Plumbing',
        'displayName': l10n.plumbing,
        'icon': Icons.plumbing,
      },
      {
        'name': 'Electrical',
        'displayName': l10n.electrical,
        'icon': Icons.electrical_services,
      },
      {
        'name': 'Cleaning',
        'displayName': l10n.cleaning,
        'icon': Icons.cleaning_services,
      },
      {
        'name': 'Gardening',
        'displayName': l10n.gardening,
        'icon': Icons.yard,
      },
      {
        'name': 'Painting',
        'displayName': l10n.painting,
        'icon': Icons.format_paint,
      },
      {
        'name': 'Carpentry',
        'displayName': l10n.carpentry,
        'icon': Icons.handyman,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    // Initialize search query from initialSearch if provided
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = _searchQuery;
    }

    // Initialize location from initialLocation if provided
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      _selectedLocation = widget.initialLocation!;
    }

    _loadProviders();
  }

  void _loadProviders({bool resetPage = false}) {
    if (!mounted) return;
    if (resetPage) {
      _currentPage = 1;
    }
    setState(() {
      _isLoadingPage = true;
    });

    final queryParams = {
      'page': _currentPage.toString(),
      'limit': _limit.toString(),
    };

    // Handle search queries
    if (_searchQuery.isNotEmpty) {
      // If the search query is prefixed with "Category:", it means
      // we're filtering by a specific category only
      if (_searchQuery.startsWith('Category: ')) {
        // Category is already set in _selectedCategory, so we don't need to add search parameter
      } else {
        // Normal search by text
        queryParams['search'] = _searchQuery;
      }
    }

    // Skip backend category filtering for now - we'll do it client-side
    // This ensures we get all providers and can filter them properly
    // Add category filter if not "All"
    // if (_selectedCategory != 'All') {
    //   // Try multiple variations of the service type for backend compatibility
    //   String categoryParam = _selectedCategory;
    //   switch (_selectedCategory) {
    //     case 'Electrical':
    //       categoryParam = 'Electrician';
    //       break;
    //     case 'Plumbing':
    //       categoryParam = 'Plumber';
    //       break;
    //     case 'Cleaning':
    //       categoryParam = 'Cleaner';
    //       break;
    //     case 'Gardening':
    //       categoryParam = 'Gardener';
    //       break;
    //     case 'Painting':
    //       categoryParam = 'Painter';
    //       break;
    //     case 'Carpentry':
    //       categoryParam = 'Carpenter';
    //       break;
    //   }
    //   queryParams['serviceType'] = categoryParam;
    // }

    // Add location filter if specified
    if (_selectedLocation.isNotEmpty) {
      queryParams['location'] = _selectedLocation;
      queryParams['serviceArea'] =
          _selectedLocation; // Also search in service areas
    }
    
    // Add user's location coordinates for distance-based search
    if (_selectedLatitude != null && _selectedLongitude != null) {
      queryParams['latitude'] = _selectedLatitude.toString();
      queryParams['longitude'] = _selectedLongitude.toString();
      final searchDistance = _maxDistance < 5.0 ? 10.0 : _maxDistance;
      queryParams['maxDistance'] = searchDistance.toString();
    }
    
    // Add availability filter
    if (_onlyAvailable) {
      queryParams['onlyAvailable'] = 'true';
    }

    // Debug: Print search parameters
    print('🔍 Search Parameters:');
    print('   Location: $_selectedLocation');
    print('   Latitude: $_selectedLatitude');
    print('   Longitude: $_selectedLongitude');
    print('   Max Distance: $_maxDistance');
    print('   Query Params: $queryParams');
    
    // Use fetchProviders for initial load, searchProviders only when there are search parameters
    final hasSearchParams = queryParams.length > 2 || // More than just page and limit
        _searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedLocation.isNotEmpty ||
        _onlyAvailable ||
        _minRating > 0.0 ||
        _maxPrice < 1000.0 ||
        _maxDistance < 50.0;
    
    _providersFuture = (hasSearchParams 
        ? _apiService.searchProviders(queryParams)
        : _apiService.fetchProviders(queryParams)
    ).then((response) {
      List<Provider> filteredProviders = response.providers;
      
      // DEBUG: Print all service types to see what's actually in the database
      if (filteredProviders.isNotEmpty) {
        print('=== DEBUG: Providers found ===');
        for (final provider in filteredProviders) {
          print('Provider: ${provider.fullName}');
          print('  Service Type: "${provider.serviceType}"');
          print('  Location: ${provider.location?.addressText}');
          print('  Coordinates: ${provider.location?.coordinates}');
          print('  Rating: ${provider.averageRating}');
          print('  Available: ${provider.isAvailable}');
          print('---');
        }
        print('=== END DEBUG ===');
      } else {
        print('❌ No providers found in search results');
      }

      // Apply client-side filtering if search query exists and backend didn't filter
      if (_searchQuery.isNotEmpty &&
          !_searchQuery.startsWith('Category: ') &&
          filteredProviders.length > 0) {
        // Get the search term for client-side filtering
        final String searchTerm = _searchQuery.toLowerCase();

        // Filter providers whose name contains the search term
        filteredProviders = filteredProviders.where((provider) {
          final fullName = (provider.fullName ?? '').toLowerCase();
          final companyName = (provider.companyName ?? '').toLowerCase();
          final serviceType = (provider.serviceType ?? '').toLowerCase();

          return fullName.contains(searchTerm) ||
              companyName.contains(searchTerm) ||
              serviceType.contains(searchTerm);
        }).toList();
      }

      // Apply additional advanced filters
      if (filteredProviders.isNotEmpty) {
        // Apply category filtering (client-side as fallback)
        if (_selectedCategory != 'All') {
          filteredProviders = filteredProviders.where((provider) {
            final serviceType = (provider.serviceType ?? '').toLowerCase();
            
            // Define possible service type variations for each category
            switch (_selectedCategory) {
              case 'Plumbing':
                return serviceType.contains('plumb') || 
                       serviceType.contains('water') ||
                       serviceType.contains('pipe');
              case 'Electrical':
                return serviceType.contains('electric') || 
                       serviceType.contains('wiring') ||
                       serviceType.contains('power');
              case 'Cleaning':
                return serviceType.contains('clean') || 
                       serviceType.contains('housekeep') ||
                       serviceType.contains('maid');
              case 'Gardening':
                return serviceType.contains('garden') || 
                       serviceType.contains('landscap') ||
                       serviceType.contains('plant');
              case 'Painting':
                return serviceType.contains('paint') || 
                       serviceType.contains('decor') ||
                       serviceType.contains('wall');
              case 'Carpentry':
                return serviceType.contains('carpen') || 
                       serviceType.contains('wood') ||
                       serviceType.contains('furniture');
              default:
                return true;
            }
          }).toList();
        }
        
        // Note: Location filtering is now handled by the backend
        // Client-side location filtering removed to avoid conflicts with backend search
        
        // Apply rating filter
        if (_minRating > 0.0) {
          filteredProviders = filteredProviders.where((provider) {
            return (provider.averageRating ?? 0.0) >= _minRating;
          }).toList();
        }
        
        // Apply price filter
        if (_maxPrice < 1000.0) {
          filteredProviders = filteredProviders.where((provider) {
            return (provider.hourlyRate ?? 0.0) <= _maxPrice;
          }).toList();
        }
        
        // Apply availability filter (backend filtering is primary, this is fallback)
        if (_onlyAvailable) {
          filteredProviders = filteredProviders.where((provider) {
            return provider.isAvailable ?? true; // Default to available if not specified
          }).toList();
        }
        
        // Apply tags filter (this would need backend support for real implementation)
        if (_selectedTags.isNotEmpty) {
          // For now, we'll simulate tag filtering
          // In a real implementation, this would check provider tags/specialties
        }
        
        // Apply distance filter (this would need location coordinates and distance calculation)
        if (_maxDistance < 50.0 && _selectedLatitude != null && _selectedLongitude != null) {
          // For now, we'll keep all providers
          // In a real implementation, this would calculate distance based on coordinates
        }
        
        // Apply sorting
        filteredProviders.sort((a, b) {
          int comparison = 0;
          
          switch (_sortBy) {
            case 'rating':
              final aRating = a.averageRating ?? 0.0;
              final bRating = b.averageRating ?? 0.0;
              comparison = aRating.compareTo(bRating);
              break;
            case 'price':
              final aPrice = a.hourlyRate ?? 0.0;
              final bPrice = b.hourlyRate ?? 0.0;
              comparison = aPrice.compareTo(bPrice);
              break;
            case 'distance':
              // For now, sort by name since we don't have distance calculation
              comparison = (a.fullName ?? '').compareTo(b.fullName ?? '');
              break;
            default:
              comparison = (a.fullName ?? '').compareTo(b.fullName ?? '');
          }
          
          // Apply sort order
          return _sortOrder == 'desc' ? -comparison : comparison;
        });
      }
      
      // Return filtered and sorted response
      return ProviderListResponse(
        providers: filteredProviders,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        totalProviders: filteredProviders.length,
      );
    });

    _providersFuture.then((response) {
      if (mounted) {
        setState(() {
          _totalPages = response.totalPages;
          _totalProviders = response.totalProviders;
          _isLoadingPage = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading page: ${error.toString()}')),
        );
      }
    });
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages && !_isLoadingPage) {
      setState(() {
        _currentPage++;
      });
      _loadProviders();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoadingPage) {
      setState(() {
        _currentPage--;
      });
      _loadProviders();
    }
  }

  void _performSearch(String query) {
    // Trim whitespace from the query
    final trimmedQuery = query.trim();

    // If a category filter is already active, and we're now adding a text search
    if (_selectedCategory != 'All' &&
        trimmedQuery.isNotEmpty &&
        !trimmedQuery.startsWith('Category: ')) {
      // Keep both filters - category stays as is, and add text search
      setState(() {
        _searchQuery = trimmedQuery;
      });
    } else {
      // Normal search query
      setState(() {
        _searchQuery = trimmedQuery;

        // If we're searching for a specific category using text (e.g., "Category: Plumbing")
        if (trimmedQuery.startsWith('Category: ')) {
          String categoryName = trimmedQuery.substring('Category: '.length);
          // Find if this category exists in our list
          bool validCategory =
              _getCategories(context).any((cat) => cat['name'] == categoryName);
          if (validCategory) {
            _selectedCategory = categoryName;
          }
        }
      });
    }

    _loadProviders(resetPage: true);
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;

      // If we're selecting a specific category, update the search UI to reflect that
      if (category != 'All') {
        _searchController.text = 'Category: $category';
      } else if (_searchQuery.startsWith('Category: ')) {
        // Clear the search box if we're deselecting a category filter
        _searchController.text = '';
      }
    });
    _loadProviders(resetPage: true);
  }

  // Clear all filters and search
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedLocation = '';
      _selectedLatitude = null;
      _selectedLongitude = null;
      _minRating = 0.0;
      _maxPrice = 1000.0;
      _maxDistance = 50.0;
      _onlyAvailable = false;
      _selectedTags.clear();
      _sortBy = 'rating';
      _sortOrder = 'desc';
      _searchController.clear();
    });
    _loadProviders(resetPage: true);
  }

  // Apply advanced filters from the AdvancedSearchScreen
  void _applyAdvancedFilters(SearchFilters filters) {
    setState(() {
      _searchQuery = filters.searchQuery;
      _selectedCategory = filters.selectedCategory;
      _selectedLocation = filters.selectedLocation;
      _selectedLatitude = filters.selectedLatitude;
      _selectedLongitude = filters.selectedLongitude;
      _minRating = filters.minRating;
      _maxPrice = filters.maxPrice;
      _maxDistance = filters.maxDistance;
      _onlyAvailable = filters.onlyAvailable;
      _selectedTags = List.from(filters.selectedTags);
      _sortBy = filters.sortBy;
      _sortOrder = filters.sortOrder;
      
      // Update the search controller to reflect the search query
      _searchController.text = filters.searchQuery;
    });
    
    _loadProviders(resetPage: true);
  }

  // Check if any filters are currently active
  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
           _selectedCategory != 'All' ||
           _selectedLocation.isNotEmpty ||
           _minRating > 0.0 ||
           _maxPrice < 1000.0 ||
           _maxDistance < 50.0 ||
           _onlyAvailable ||
           _selectedTags.isNotEmpty ||
           _sortBy != 'rating' ||
           _sortOrder != 'desc';
  }

  // This is a helper method for development to show some sample data
  // when the backend is not returning results. Remove in production.
  void _createSampleData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sample Data Mode'),
        content: Text(
            'This will display sample data for testing purposes. The data is not real and not saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                // Create and show a sample provider with the name containing the search term
                final sampleProvider = Provider(
                  id: 'sample-1',
                  fullName: _searchQuery.isNotEmpty
                      ? 'Amer Professional Services'
                      : 'John Doe',
                  companyName: _searchQuery.isNotEmpty
                      ? 'Amer IT Solutions'
                      : 'ABC Company',
                  serviceType: _selectedCategory != 'All'
                      ? _selectedCategory
                      : 'General Services',
                  hourlyRate: 75.0,
                  averageRating: 4.5,
                  totalRatings: 12,
                  serviceDescription:
                      'Professional services with years of experience',
                  location: ProviderLocation(
                    addressText: 'New York, NY',
                    coordinates: [-74.0060, 40.7128],
                  ),
                );

                _providersFuture = Future.value(ProviderListResponse(
                  providers: [sampleProvider],
                  currentPage: 1,
                  totalPages: 1,
                  totalProviders: 1,
                ));
              });
            },
            child: Text('Show Sample Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }


  // Add this method to handle location selection
  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
    });
    _loadProviders(resetPage: true);
  }

  // Show a dialog to select location
  void _showLocationSelectionDialog() {
    // List of Jordanian cities
    final List<String> jordanCities = [
      'Amman',
      'Irbid',
      'Zarqa',
      'Mafraq',
      'Ajloun',
      'Jerash',
      'Madaba',
      'Balqa',
      'Karak',
      'Tafileh',
      'Maan',
      'Aqaba',
    ];

    // Selected city (initially the current location)
    String selectedCity = _selectedLocation;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select City'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jordanCities.length,
                    itemBuilder: (context, index) {
                      final city = jordanCities[index];
                      return ListTile(
                        title: Text(city),
                        trailing: selectedCity == city
                            ? Icon(Icons.check, color: AppTheme.primary)
                            : null,
                        onTap: () {
                          selectedCity = city;
                          Navigator.of(context).pop();
                          _selectLocation(city);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear location filter
                _selectLocation('');
              },
              child: Text('Clear Filter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService =
        ctxProvider.Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.light,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _selectedLocation.isNotEmpty
              ? AppLocalizations.of(context)!.providersIn(_selectedLocation)
              : _searchQuery.isNotEmpty && !_searchQuery.startsWith('Category:')
                  ? AppLocalizations.of(context)!.resultsFor(_searchQuery)
                  : AppLocalizations.of(context)!.serviceProviders,
          style: AppTheme.h3.copyWith(color: AppTheme.dark),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: AppTheme.primary),
            tooltip: AppLocalizations.of(context)!.advancedSearch,
            onPressed: () async {
              final result = await Navigator.push<SearchFilters>(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvancedSearchScreen(
                    initialSearch: _searchQuery.isNotEmpty ? _searchQuery : null,
                    initialLocation: _selectedLocation.isNotEmpty ? _selectedLocation : null,
                    onFiltersApplied: null, // We'll handle the result via the return value
                  ),
                ),
              );
              
              if (result != null) {
                _applyAdvancedFilters(result);
              }
            },
          ),
          if (_hasActiveFilters())
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: AppTheme.primary),
              tooltip: AppLocalizations.of(context)!.clearFilters,
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.dark),
            tooltip: AppLocalizations.of(context)!.refreshList,
            onPressed: () => _loadProviders(resetPage: true),
          ),
          if (_selectedLocation.isNotEmpty)
            IconButton(
              icon: Icon(Icons.location_on, color: AppTheme.primary),
              tooltip: AppLocalizations.of(context)!.cityLabel(_selectedLocation),
              onPressed: () {
                // Show location selection dialog
                _showLocationSelectionDialog();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: FutureBuilder<ProviderListResponse>(
              future: _providersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppLocalizations.of(context)!.errorLoadingProvidersMessage(snapshot.error.toString()),
                        textAlign: TextAlign.center,
                        style: AppTheme.body3.copyWith(color: AppTheme.danger),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.providers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppTheme.grey),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noProvidersFound,
                          style: AppTheme.h3.copyWith(color: AppTheme.dark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results match "${_searchQuery}"'
                              : _selectedCategory != 'All'
                                  ? 'No providers in ${_selectedCategory} category'
                                  : 'Add some via your API or try refreshing',
                          style: AppTheme.body3.copyWith(color: AppTheme.grey),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.clear, color: AppTheme.white),
                              label: Text('Clear Filters',
                                  style: TextStyle(color: AppTheme.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radius),
                                ),
                              ),
                              onPressed: _clearFilters,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final providerListResponse = snapshot.data!;
                final providers = providerListResponse.providers;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _buildProviderCard(provider);
                  },
                );
              },
            ),
          ),
          if (_totalProviders > 0) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.white,
      child: Column(
        children: [
          // Search box
          Container(
            decoration: BoxDecoration(
              color: AppTheme.light,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              boxShadow: [AppTheme.lightShadow],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByNameOrServiceType,
                hintStyle: TextStyle(color: AppTheme.grey),
                prefixIcon: Icon(Icons.search, color: AppTheme.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                // Only search if we have 2+ characters or empty string (to clear search)
                if (value.length >= 2 || value.isEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),

          // Location filter indicator
          if (_selectedLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: _showLocationSelectionDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.cityLabel(_selectedLocation),
                        style: TextStyle(color: AppTheme.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = _getCategories(context);
    return Container(
      height: 80,
      color: AppTheme.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['name'];

          return GestureDetector(
            onTap: () => _selectCategory(category['name']),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primary : AppTheme.greyLight,
                      ),
                      boxShadow: isSelected ? [AppTheme.lightShadow] : null,
                    ),
                    child: Icon(
                      category['icon'],
                      color: isSelected ? AppTheme.white : AppTheme.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category['displayName'] ?? category['name'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(Provider provider) {
    // Determine provider location info
    String? providerCity = provider.location?.city;
    String? addressText = provider.location?.addressText;

    // Highlight the location if it matches the selected filter
    final bool locationMatches = _selectedLocation.isNotEmpty &&
        ((providerCity
                    ?.toLowerCase()
                    .contains(_selectedLocation.toLowerCase()) ??
                false) ||
            (addressText
                    ?.toLowerCase()
                    .contains(_selectedLocation.toLowerCase()) ??
                false));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            ProviderDetailScreen.routeName,
            arguments: provider.id ?? '',
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProviderAvatar(provider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.companyName ?? provider.fullName ?? 'N/A',
                            style: AppTheme.h3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\$${provider.hourlyRate ?? 'N/A'}/hr',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ServiceTypeLocalizer.getLocalizedServiceType(provider.serviceType, AppLocalizations.of(context)!),
                            style: TextStyle(color: AppTheme.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location information with icon
                    if (providerCity != null || addressText != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: locationMatches
                                ? AppTheme.primary
                                : AppTheme.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              providerCity != null
                                  ? (addressText != null
                                      ? '$providerCity, $addressText'
                                      : providerCity)
                                  : (addressText ?? 'Location not specified'),
                              style: TextStyle(
                                color: locationMatches
                                    ? AppTheme.primary
                                    : AppTheme.grey,
                                fontWeight: locationMatches
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRatingStars(provider.averageRating),
                        const SizedBox(width: 4),
                        Text(
                          provider.totalRatings != null
                              ? '(${provider.totalRatings})'
                              : '(0)',
                          style: TextStyle(color: AppTheme.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    if (provider.serviceDescription != null &&
                        provider.serviceDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.serviceDescription!,
                          style: TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderAvatar(Provider provider) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(provider.fullName ?? provider.companyName ?? 'P'),
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name.isNotEmpty ? name[0].toUpperCase() : 'P';
    }
  }

  Widget _buildRatingStars(double? rating) {
    final actualRating = rating ?? 0.0;
    return Row(
      children: List.generate(5, (index) {
        if (index < actualRating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == actualRating.floor() && actualRating % 1 > 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppTheme.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPaginationButton(
            icon: Icons.arrow_back_ios,
            onPressed: (_currentPage > 1 && !_isLoadingPage)
                ? _goToPreviousPage
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPaginationButton(
            icon: Icons.arrow_forward_ios,
            onPressed: (_currentPage < _totalPages && !_isLoadingPage)
                ? _goToNextPage
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: onPressed != null ? AppTheme.primary : AppTheme.greyLight,
      tooltip: onPressed != null
          ? (icon == Icons.arrow_back_ios ? 'Previous Page' : 'Next Page')
          : null,
    );
  }
}
