// Temporarily disabled due to missing dependencies
/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/provider_model.dart';
import '../services/auth_service.dart';
import '../services/provider_service.dart';
import '../services/location_service.dart';
import '../widgets/provider_info_card.dart';
*/

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

// Temporarily disabled due to missing dependencies
class MapViewScreen extends StatefulWidget {
  static const routeName = '/map-view';

  const MapViewScreen({Key? key}) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  // Temporarily disabled due to missing dependencies
  /*
  final ProviderService _providerService = ProviderService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _locationPermissionDenied = false;
  String? _errorMessage;
  List<Provider> _nearbyProviders = [];
  LatLng _currentLocation = LatLng(31.9539, 35.9106); // Default to Amman
  double _searchRadius = 10.0; // Default radius in km
  String? _selectedCategory;
  */

  @override
  void initState() {
    super.initState();
    // _initializeLocationAndProviders();
  }

  /*
  Future<void> _initializeLocationAndProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check location permission
      final permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionDenied = true;
          _isLoading = false;
        });
        return;
      }

      // Get current location
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }

      // Fetch nearby providers
      await _fetchNearbyProviders();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing map: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  */

  /*
  Future<void> _fetchNearbyProviders() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token != null) {
        final providers = await _providerService.getNearbyProviders(
          token: token,
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
          distance: _searchRadius,
          category: _selectedCategory,
        );

        setState(() {
          _nearbyProviders = providers;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching nearby providers: $e';
      });
    }
  }
  */

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await _locationService.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _locationPermissionDenied = false;
        });
        await _initializeLocationAndProviders();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error requesting permission: $e';
      });
    }
  }

  Future<void> _updateSearchRadius(double radius) async {
    setState(() {
      _searchRadius = radius;
    });
    await _fetchNearbyProviders();
  }

  Future<void> _updateCategory(String? category) async {
    setState(() {
      _selectedCategory = category;
    });
    await _fetchNearbyProviders();
  }

  void _onTapMarker(Provider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(16),
        child: ProviderInfoCard(provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mapView),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.mapFunctionalityDisabled),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationPermissionDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Location permission is required to show nearby providers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestLocationPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeLocationAndProviders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentLocation,
            zoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                // Current location marker
                Marker(
                  point: _currentLocation,
                  width: 40,
                  height: 40,
                  builder: (ctx) => const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                // Provider markers
                ..._nearbyProviders.map((provider) {
                  if (provider.location?.coordinates == null ||
                      provider.location!.coordinates!.length != 2) {
                    return const Marker(
                      point: LatLng(0, 0),
                      width: 0,
                      height: 0,
                      builder: SizedBox.shrink,
                    );
                  }

                  return Marker(
                    point: LatLng(
                      provider.location!.coordinates![1], // latitude
                      provider.location!.coordinates![0], // longitude
                    ),
                    width: 40,
                    height: 40,
                    builder: (ctx) => GestureDetector(
                      onTap: () => _onTapMarker(provider),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(provider.serviceCategory),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _currentLocation,
                  radius: _searchRadius * 1000, // Convert km to meters
                  color: Colors.blue.withOpacity(0.2),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Found ${_nearbyProviders.length} providers nearby',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Text('Category: $_selectedCategory'),
                          TextButton(
                            onPressed: () => _updateCategory(null),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  Text('Search radius: ${_searchRadius.toStringAsFixed(1)} km'),
                  Slider(
                    value: _searchRadius,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    label: '${_searchRadius.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() {
                        _searchRadius = value;
                      });
                    },
                    onChangeEnd: (value) => _updateSearchRadius(value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Providers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a category:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('All Categories'),
              value: _selectedCategory,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._getServiceCategories().map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'] as String,
                    child: Text(category['name'] as String),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                Navigator.of(ctx).pop();
                _updateCategory(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'home_repair':
        return Icons.handyman;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'gardening':
        return Icons.grass;
      case 'moving':
        return Icons.local_shipping;
      case 'tutoring':
        return Icons.school;
      case 'pet_care':
        return Icons.pets;
      case 'beauty':
        return Icons.spa;
      case 'wellness':
        return Icons.favorite;
      case 'photography':
        return Icons.camera_alt;
      case 'graphic_design':
        return Icons.brush;
      case 'web_development':
        return Icons.computer;
      case 'legal':
        return Icons.gavel;
      case 'automotive':
        return Icons.directions_car;
      case 'event_planning':
        return Icons.event;
      case 'personal_training':
        return Icons.fitness_center;
      case 'cooking':
        return Icons.restaurant;
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.work;
    }
  }

  List<Map<String, String>> _getServiceCategories() {
    return [
      {'id': 'cleaning', 'name': 'Cleaning Services'},
      {'id': 'home_repair', 'name': 'Home Repair & Maintenance'},
      {'id': 'plumbing', 'name': 'Plumbing Services'},
      {'id': 'electrical', 'name': 'Electrical Services'},
      {'id': 'gardening', 'name': 'Gardening & Landscaping'},
      {'id': 'moving', 'name': 'Moving & Delivery'},
      {'id': 'tutoring', 'name': 'Tutoring & Education'},
      {'id': 'pet_care', 'name': 'Pet Care Services'},
      {'id': 'beauty', 'name': 'Beauty & Spa Services'},
      {'id': 'wellness', 'name': 'Health & Wellness'},
      {'id': 'photography', 'name': 'Photography & Videography'},
      {'id': 'graphic_design', 'name': 'Graphic Design'},
      {'id': 'web_development', 'name': 'Web Development'},
      {'id': 'legal', 'name': 'Legal Services'},
      {'id': 'automotive', 'name': 'Automotive Services'},
      {'id': 'event_planning', 'name': 'Event Planning'},
      {'id': 'personal_training', 'name': 'Personal Training'},
      {'id': 'cooking', 'name': 'Cooking & Catering'},
      {'id': 'delivery', 'name': 'Delivery Services'},
      {'id': 'other', 'name': 'Other Services'},
    ];
  }
}
