import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatefulWidget {
  final String? initialAddress;
  final Function(String address, double latitude, double longitude) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng _selectedLocation = const LatLng(31.9539, 35.9106); // Default to Amman
  String _selectedAddress = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _searchController.text = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we have an initial address
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        await _geocodeAddress(widget.initialAddress!);
      } else {
        // Get current location
        await _getCurrentLocation();
      }
    } catch (e) {
      // If location services fail, use default location
      _selectedLocation = const LatLng(31.9539, 35.9106); // Amman
      _selectedAddress = 'Amman, Jordan';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Reverse geocode to get address
      await _reverseGeocode(_selectedLocation);
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  Future<void> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _selectedAddress = address;
        });
        
        // Move map to the new location
        _mapController.move(_selectedLocation, 15.0);
      }
    } catch (e) {
      throw Exception('Failed to geocode address: $e');
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _selectedAddress = [
            placemark.street,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((element) => element != null && element.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      // If reverse geocoding fails, use coordinates as address
      setState(() {
        _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
    }
  }

  void _confirmLocation() {
    widget.onLocationSelected(
      _selectedAddress,
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );
    Navigator.of(context).pop();
  }

  void _searchLocation() async {
    if (_searchController.text.isNotEmpty) {
      try {
        await _geocodeAddress(_searchController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    
    // Reverse geocode to get address
    _reverseGeocode(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1D1D1F),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Color(0xFF34C759),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a location...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location, color: Color(0xFF34C759)),
                          onPressed: () async {
                            try {
                              await _getCurrentLocation();
                              _mapController.move(_selectedLocation, 15.0);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error getting location: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      onSubmitted: (_) => _searchLocation(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          
          // Map Container
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF007AFF),
                    ),
                  )
                : _buildMapView(isDark),
          ),
          
          // Location Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF34C759),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress.isNotEmpty ? _selectedAddress : 'Tap on map to select location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedLocation,
        initialZoom: 15.0,
        onTap: _onMapTap,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        // OpenStreetMap tiles with better configuration
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.joservice.app',
          maxZoom: 18,
          subdomains: const ['a', 'b', 'c'],
          additionalOptions: const {
            'crossOrigin': 'anonymous',
          },
          errorTileCallback: (tile, error, stackTrace) {
          },
          // Fallback to alternative tile servers if needed
          fallbackUrl: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
        ),
        
        // Marker for selected location
        MarkerLayer(
          markers: [
            Marker(
              point: _selectedLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34C759).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        
        // Custom zoom controls overlay
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF34C759)),
                        onPressed: () {
                          final currentZoom = _mapController.zoom;
                          _mapController.move(_mapController.center, currentZoom + 1);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Color(0xFF34C759)),
                        onPressed: () {
                          final currentZoom = _mapController.zoom;
                          _mapController.move(_mapController.center, currentZoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 