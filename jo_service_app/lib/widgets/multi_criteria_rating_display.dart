import 'package:flutter/material.dart';
import '../models/rating_model.dart';

class MultiCriteriaRatingDisplay extends StatelessWidget {
  final ProviderRatingStats ratingStats;
  final bool showRecentReviews;
  final bool isCompact;

  const MultiCriteriaRatingDisplay({
    Key? key,
    required this.ratingStats,
    this.showRecentReviews = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with overall rating
        _buildOverallRatingHeader(),
        
        const SizedBox(height: 16),
        
        // Criteria breakdown
        _buildCriteriaBreakdown(),
        
        if (showRecentReviews && ratingStats.recentRatings.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRecentReviews(context),
        ],
      ],
    );
  }

  Widget _buildOverallRatingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Overall rating display
          Column(
            children: [
              Text(
                ratingStats.overallAverageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      i <= ratingStats.overallAverageRating 
                          ? Icons.star 
                          : Icons.star_border,
                      color: i <= ratingStats.overallAverageRating 
                          ? Colors.amber 
                          : Colors.grey[400],
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${ratingStats.totalRatings} reviews',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 20),
          
          // Criteria preview
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rating Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCompactCriteriaItem(
                  'Punctuality', 
                  ratingStats.averagePunctuality,
                  Colors.green,
                ),
                _buildCompactCriteriaItem(
                  'Work Quality', 
                  ratingStats.averageWorkQuality,
                  Colors.blue,
                ),
                _buildCompactCriteriaItem(
                  'Speed & Efficiency', 
                  ratingStats.averageSpeedAndEfficiency,
                  Colors.orange,
                ),
                _buildCompactCriteriaItem(
                  'Cleanliness', 
                  ratingStats.averageCleanliness,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCriteriaItem(String label, double rating, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                for (int i = 1; i <= 5; i++)
                  Icon(
                    i <= rating ? Icons.star : Icons.star_border,
                    color: i <= rating ? color : Colors.grey[300],
                    size: 12,
                  ),
              ],
            ),
          ),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBreakdown() {
    if (isCompact) {
      return const SizedBox.shrink(); // Skip detailed breakdown in compact mode
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Ratings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildDetailedCriteriaItem(
          title: 'Punctuality',
          description: 'Provider arrives on time',
          icon: Icons.access_time,
          color: Colors.green,
          rating: ratingStats.averagePunctuality,
        ),
        
        _buildDetailedCriteriaItem(
          title: 'Work Quality',
          description: 'Quality of service provided',
          icon: Icons.work_outline,
          color: Colors.blue,
          rating: ratingStats.averageWorkQuality,
        ),
        
        _buildDetailedCriteriaItem(
          title: 'Speed & Efficiency',
          description: 'How efficiently service is completed',
          icon: Icons.speed,
          color: Colors.orange,
          rating: ratingStats.averageSpeedAndEfficiency,
        ),
        
        _buildDetailedCriteriaItem(
          title: 'Cleanliness',
          description: 'Work area cleanliness after completion',
          icon: Icons.cleaning_services,
          color: Colors.purple,
          rating: ratingStats.averageCleanliness,
        ),
      ],
    );
  }

  Widget _buildDetailedCriteriaItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required double rating,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: rating / 5.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      i <= rating ? Icons.star : Icons.star_border,
                      color: i <= rating ? color : Colors.grey[300],
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviews(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        ...ratingStats.recentRatings.take(3).map((rating) => 
          _buildReviewItem(rating)
        ).toList(),
        
        if (ratingStats.recentRatings.length > 3)
          TextButton(
            onPressed: () {
              // Navigate to all reviews screen
              _showAllReviews(context);
            },
            child: Text('View all ${ratingStats.totalRatings} reviews'),
          ),
      ],
    );
  }

  Widget _buildReviewItem(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  'U',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          Icon(
                            i <= rating.overallRating 
                                ? Icons.star 
                                : Icons.star_border,
                            color: i <= rating.overallRating 
                                ? Colors.amber 
                                : Colors.grey[400],
                            size: 16,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          rating.overallRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (rating.createdAt != null)
                      Text(
                        _formatDate(rating.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              rating.review!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
          
          // Show criteria breakdown for this review
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildMiniCriteriaChip('Punctuality', rating.punctuality, Colors.green),
              _buildMiniCriteriaChip('Quality', rating.workQuality, Colors.blue),
              _buildMiniCriteriaChip('Speed', rating.speedAndEfficiency, Colors.orange),
              _buildMiniCriteriaChip('Cleanliness', rating.cleanliness, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCriteriaChip(String label, double rating, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            size: 12,
            color: color,
          ),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'All Reviews (${ratingStats.totalRatings})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: ratingStats.recentRatings.length,
                  itemBuilder: (context, index) => 
                      _buildReviewItem(ratingStats.recentRatings[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
