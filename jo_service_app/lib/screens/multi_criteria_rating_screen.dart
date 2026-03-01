import 'package:flutter/material.dart';
import '../services/rating_service.dart';
import '../services/auth_service.dart';
import '../models/booking_model.dart';
import '../models/rating_model.dart';

class MultiCriteriaRatingScreen extends StatefulWidget {
  final Booking booking;

  const MultiCriteriaRatingScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<MultiCriteriaRatingScreen> createState() => _MultiCriteriaRatingScreenState();
}

class _MultiCriteriaRatingScreenState extends State<MultiCriteriaRatingScreen>
    with TickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  final AuthService _authService = AuthService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Rating values for each criterion
  double _punctualityRating = 0.0;
  double _workQualityRating = 0.0;
  double _speedEfficiencyRating = 0.0;
  double _cleanlinessRating = 0.0;

  String _review = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    // Validate that provider information is available
    if (widget.booking.provider?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that all ratings are provided
    if (_punctualityRating == 0.0 ||
        _workQualityRating == 0.0 ||
        _speedEfficiencyRating == 0.0 ||
        _cleanlinessRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate all criteria before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Calculate overall rating for backend compatibility
      final overallRating = Rating.calculateOverallRating(
        punctuality: _punctualityRating,
        workQuality: _workQualityRating,
        speedAndEfficiency: _speedEfficiencyRating,
        cleanliness: _cleanlinessRating,
      );

      await _ratingService.rateProviderLegacy(
        token: token,
        bookingId: widget.booking.id,
        providerId: widget.booking.provider!.id!,
        rating: overallRating,
        review: _review.isNotEmpty ? _review : null,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context, true); // Return true to indicate rating was submitted
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildRatingCriterion({
    required String title,
    required String description,
    required IconData icon,
    required double rating,
    required Function(double) onRatingChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => onRatingChanged(i.toDouble()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: i <= rating ? Colors.amber : Colors.grey[400],
                        size: 36,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Rating text
            if (rating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    _getRatingText(rating),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Widget _buildOverallRating() {
    final overallRating = Rating.calculateOverallRating(
      punctuality: _punctualityRating,
      workQuality: _workQualityRating,
      speedAndEfficiency: _speedEfficiencyRating,
      cleanliness: _cleanlinessRating,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: Colors.blue,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Overall Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  Icon(
                    i <= overallRating ? Icons.star : Icons.star_border,
                    color: i <= overallRating ? Colors.amber : Colors.grey[400],
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${overallRating.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Rate Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star_rate,
                        size: 48,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'How was your experience?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please rate each aspect of the service',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Rating Criteria
                _buildRatingCriterion(
                  title: 'Punctuality',
                  description: 'Did the provider arrive on time?',
                  icon: Icons.access_time,
                  color: Colors.green,
                  rating: _punctualityRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _punctualityRating = rating;
                    });
                  },
                ),

                _buildRatingCriterion(
                  title: 'Work Quality',
                  description: 'How satisfied are you with the quality of work?',
                  icon: Icons.work_outline,
                  color: Colors.blue,
                  rating: _workQualityRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _workQualityRating = rating;
                    });
                  },
                ),

                _buildRatingCriterion(
                  title: 'Speed and Efficiency',
                  description: 'How efficiently was the service completed?',
                  icon: Icons.speed,
                  color: Colors.orange,
                  rating: _speedEfficiencyRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _speedEfficiencyRating = rating;
                    });
                  },
                ),

                _buildRatingCriterion(
                  title: 'Cleanliness',
                  description: 'How clean was the work area after completion?',
                  icon: Icons.cleaning_services,
                  color: Colors.purple,
                  rating: _cleanlinessRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _cleanlinessRating = rating;
                    });
                  },
                ),

                // Overall Rating Display
                if (_punctualityRating > 0 &&
                    _workQualityRating > 0 &&
                    _speedEfficiencyRating > 0 &&
                    _cleanlinessRating > 0)
                  _buildOverallRating(),

                // Review Section
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.rate_review,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Write a Review (Optional)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Share your experience with this service...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue[600]!),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 4,
                          onChanged: (value) {
                            _review = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submitting...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Submit Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
