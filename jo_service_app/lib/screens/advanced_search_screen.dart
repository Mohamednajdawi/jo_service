import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/location_picker.dart';

class SearchFilters {
  final String searchQuery;
  final String selectedCategory;
  final String selectedLocation;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final double minRating;
  final double maxPrice;
  final double maxDistance;
  final bool onlyAvailable;
  final List<String> selectedTags;
  final String sortBy;
  final String sortOrder;

  SearchFilters({
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedLocation,
    this.selectedLatitude,
    this.selectedLongitude,
    required this.minRating,
    required this.maxPrice,
    required this.maxDistance,
    required this.onlyAvailable,
    required this.selectedTags,
    required this.sortBy,
    required this.sortOrder,
  });
}

class AdvancedSearchScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialLocation;
  final Function(SearchFilters)? onFiltersApplied;

  const AdvancedSearchScreen({
    this.initialSearch,
    this.initialLocation,
    this.onFiltersApplied,
    super.key,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Search parameters
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

  // Filter options - service tags removed

  @override
  void initState() {
    super.initState();
    
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = _searchQuery;
    }

    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      _selectedLocation = widget.initialLocation!;
      _locationController.text = _selectedLocation;
    }

    _maxPriceController.text = _maxPrice.toString();
  }
  

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
      _locationController.clear();
      _maxPriceController.text = _maxPrice.toString();
    });
  }

  void _openLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialAddress: _selectedLocation,
          onLocationSelected: (address, latitude, longitude) {
            setState(() {
              _selectedLocation = address;
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
              _locationController.text = address;
            });
          },
        ),
      ),
    );
  }

  void _applyFilters() {
    final filters = SearchFilters(
      searchQuery: _searchQuery,
      selectedCategory: _selectedCategory,
      selectedLocation: _selectedLocation,
      selectedLatitude: _selectedLatitude,
      selectedLongitude: _selectedLongitude,
      minRating: _minRating,
      maxPrice: _maxPrice,
      maxDistance: _maxDistance,
      onlyAvailable: _onlyAvailable,
      selectedTags: List.from(_selectedTags),
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    
    if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!(filters);
    }
    
    Navigator.of(context).pop(filters);
  }

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

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Search',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: _searchController,
              placeholder: 'Search for services...',
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.search, color: AppTheme.systemGray, size: 20),
              ),
              suffix: _searchQuery.isNotEmpty
                  ? CupertinoButton(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(CupertinoIcons.clear_circled_solid,
                          color: AppTheme.systemGray, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Location',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: _locationController,
              placeholder: 'Enter location...',
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.location, color: AppTheme.systemGray, size: 20),
              ),
              suffix: CupertinoButton(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(CupertinoIcons.map, color: AppTheme.primary, size: 20),
                onPressed: _openLocationPicker,
              ),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Category',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getCategories(context).map((category) {
                final isSelected = _selectedCategory == category['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.systemGray6,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category['displayName'],
                      style: AppTheme.body4.copyWith(
                        color: isSelected ? AppTheme.white : AppTheme.dark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Minimum Rating: ${_minRating.toStringAsFixed(1)}',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoSlider(
              value: _minRating,
              min: 0.0,
              max: 5.0,
              divisions: 10,
              activeColor: AppTheme.primary,
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Maximum Price',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: _maxPriceController,
              placeholder: 'Enter max price...',
              keyboardType: TextInputType.number,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.money_dollar, color: AppTheme.systemGray, size: 20),
              ),
              onChanged: (value) {
                final price = double.tryParse(value);
                if (price != null && price > 0) {
                  setState(() {
                    _maxPrice = price;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDistanceSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Maximum Distance: ${_maxDistance.toStringAsFixed(0)} km',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoSlider(
              value: _maxDistance,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              activeColor: AppTheme.primary,
              onChanged: (value) {
                setState(() {
                  _maxDistance = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Only Available',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
            CupertinoSwitch(
              value: _onlyAvailable,
              activeColor: AppTheme.primary,
              onChanged: (value) {
                setState(() {
                  _onlyAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSortSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sort By',
              style: AppTheme.h4.copyWith(
                color: AppTheme.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _sortBy,
                    children: const {
                      'rating': Text('Rating'),
                      'price': Text('Price'),
                      'distance': Text('Distance'),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _sortOrder,
                    children: const {
                      'desc': Text('High to Low'),
                      'asc': Text('Low to High'),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortOrder = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemGray6,
      appBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.white,
        border: const Border(),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Cancel',
            style: AppTheme.body3.copyWith(color: AppTheme.primary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          'Search Filters',
          style: AppTheme.h3.copyWith(
            color: AppTheme.dark,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Reset',
            style: AppTheme.body3.copyWith(color: AppTheme.systemGray),
          ),
          onPressed: _clearFilters,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),
                  _buildRatingSection(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  _buildDistanceSection(),
                  const SizedBox(height: 24),
                  _buildAvailabilitySection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: Border(
                top: BorderSide(
                  color: AppTheme.systemGray5,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
                onPressed: _applyFilters,
                child: Text(
                  'Apply Filters',
                  style: AppTheme.h4.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 