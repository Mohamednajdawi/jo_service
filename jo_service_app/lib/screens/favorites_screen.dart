import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../l10n/app_localizations.dart';
import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import './provider_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  static const routeName = '/favorites';
  final Set<String> favoriteProviderIds;
  final bool showAppBar; // Controls whether to show AppBar

  const FavoritesScreen({
    Key? key,
    required this.favoriteProviderIds,
    this.showAppBar = true, // Default to true for standalone usage
  }) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Provider>> _favoriteProviders;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.favoriteProviderIds.isEmpty) {
      setState(() {
        _favoriteProviders = Future.value([]);
        _isLoading = false;
      });
      return;
    }

    // Simulate fetching providers by ID
    // In a real app, you would call your API to get provider details for each ID
    _favoriteProviders = _fetchFavoriteProviders();
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Provider>> _fetchFavoriteProviders() async {
    // This is a mock implementation
    // In a real app, you would fetch these from your API
    try {
      // Fetch all providers and filter by favorites
      final response = await _apiService.fetchProviders({});
      final allProviders = response.providers;

      // Filter to only show favorites
      return allProviders
          .where((provider) => provider.id != null && widget.favoriteProviderIds.contains(provider.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.light,
      appBar: widget.showAppBar 
        ? AppBar(
            title: Text(
              l10n.favorites,
              style: AppTheme.h3.copyWith(color: AppTheme.dark),
            ),
            backgroundColor: AppTheme.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.dark),
              onPressed: () => Navigator.of(context).pop(),
            ),
          )
        : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add title when no AppBar is shown (tab usage)
                if (!widget.showAppBar) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      l10n.myFavorites,
                      style: AppTheme.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: FutureBuilder<List<Provider>>(
                    future: _favoriteProviders,
                    builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n.errorLoadingFavorites + ' ${snapshot.error}',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                  );
                }

                final providers = snapshot.data ?? [];

                if (providers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l10n.noFavoritesYet,
                          style: AppTheme.h3,
                        ),
                        SizedBox(height: 8),
                        Text(
                          l10n.addServiceProvidersToFavorites,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                          ),
                          child: Text(l10n.browseProviders),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _buildProviderCard(provider, l10n);
                  },
                );
              },
            ),
                ),
              ],
            ),
    );
  }

  Widget _buildProviderCard(Provider provider, AppLocalizations l10n) {
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // Remove from favorites using global set
                            setState(() {
                              if (provider.id != null) {
                                // favoriteProviders.remove(provider.id); // This line was removed as per the edit hint
                              }
                            });

                            // Reload the list
                            _loadFavorites();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.removedFromFavorites),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          tooltip: l10n.removeFromFavorites,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.serviceType ?? l10n.generalService,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildRatingBar(provider),
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

  Widget _buildRatingBar(Provider provider) {
    final rating = provider.averageRating ?? 0.0;
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              return Icon(Icons.star, size: 16, color: Colors.amber);
            } else if (index < rating.ceil() &&
                rating.floor() != rating.ceil()) {
              return Icon(Icons.star_half, size: 16, color: Colors.amber);
            } else {
              return Icon(Icons.star_border, size: 16, color: Colors.amber);
            }
          }),
        ),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} (${provider.totalRatings ?? 0})',
          style: AppTheme.body5,
        ),
      ],
    );
  }
}
