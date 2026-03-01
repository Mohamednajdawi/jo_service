import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import '../models/provider_model.dart' as provider_model;
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/api_service.dart';
import '../widgets/location_picker.dart';

class CreateBookingScreen extends StatefulWidget {
  final provider_model.Provider serviceProvider;

  const CreateBookingScreen({super.key, required this.serviceProvider});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  
  // Photo attachment functionality
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Function to show image picker options
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to remove selected image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Function to pick date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
          const Duration(days: 90)), // Allow booking up to 3 months in advance
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to pick time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Function to pick location
  Future<void> _pickLocation() async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LocationPicker(
            initialAddress: _locationController.text.isNotEmpty ? _locationController.text : null,
            onLocationSelected: (address, latitude, longitude) {
              setState(() {
                _locationController.text = address;
                _selectedLatitude = latitude;
                _selectedLongitude = longitude;
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening location picker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get combined date and time
  DateTime _getCombinedDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  // Submit booking request
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        return;
      }


      // Prepare photo paths
      final List<String> photoPaths = _selectedImages.map((file) => file.path).toList();

      final booking = await _bookingService.createBooking(
        token: token,
        providerId: widget.serviceProvider.id ?? '',
        serviceDateTime: _getCombinedDateTime(),
        serviceLocationDetails: _locationController.text,
        userNotes: _notesController.text,
        photoPaths: photoPaths,
      );


      // Images will be automatically available in chat through the booking system
      if (photoPaths.isNotEmpty) {
      } else {
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking request submitted successfully!')),
        );

        // Pop back to previous screen
        Navigator.of(context).pop(booking);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
      }
    }
  }

  // Method to send booking images to chat automatically
  Future<void> _sendBookingImagesToChat(String token, Booking booking, List<String> photoPaths) async {
    try {
      
      // Create a message that indicates booking images were shared
      final message = _notesController.text.isNotEmpty 
        ? 'Booking images shared with notes: ${_notesController.text}'
        : 'Booking images shared for service on ${DateFormat('MMM dd, yyyy').format(_getCombinedDateTime())}';
      
      final baseUrl = ApiService.getBaseUrl();
      
      // Send images to the chat endpoint
      final uri = Uri.parse('$baseUrl/chats/${widget.serviceProvider.id ?? 'unknown'}/images');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add booking information
      request.fields['bookingId'] = booking.id;
      request.fields['message'] = message;
      request.fields['messageType'] = 'booking_images';
      
      // Add all image files
      for (int i = 0; i < photoPaths.length; i++) {
        final file = File(photoPaths[i]);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images', // Use 'images' as the field name
              file.path,
            ),
          );
        }
      }
      
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        // Don't throw error - this is not critical to booking creation
      }
      
    } catch (e) {
      // Don't throw error - this is not critical to booking creation
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate =
        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Service'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: widget.serviceProvider
                                              .profilePictureUrl !=
                                          null
                                      ? NetworkImage(widget
                                          .serviceProvider.profilePictureUrl!)
                                      : const AssetImage(
                                              'assets/default_user.png')
                                          as ImageProvider,
                                  radius: 30,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.serviceProvider.fullName ??
                                            l10n.unknownProvider,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.serviceProvider.serviceType ??
                                            l10n.unknownService,
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                      if (widget.serviceProvider.hourlyRate !=
                                          null)
                                        Text(
                                          '${l10n.rate}: \$${widget.serviceProvider.hourlyRate}/${l10n.hour}',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Select Date & Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 16),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time picker
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 16),
                            Text(
                              formattedTime,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Service Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'Enter service location details',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a service location';
                              }
                              return null;
                            },
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: IconButton(
                            onPressed: _pickLocation,
                            icon: const Icon(Icons.map_rounded),
                            tooltip: 'Pick location on map',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Any special requests or information?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Photo attachment section
                    Row(
                      children: [
                        const Text(
                          'Attach Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showImagePickerOptions,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Add Photo'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Display selected images
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    
                    if (_selectedImages.isNotEmpty)
                      const SizedBox(height: 8),
                    
                    if (_selectedImages.isNotEmpty)
                      Text(
                        '${_selectedImages.length} photo(s) selected',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          'Submit Booking Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
