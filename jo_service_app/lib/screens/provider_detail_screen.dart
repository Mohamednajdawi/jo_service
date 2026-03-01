import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart';
import '../models/chat_conversation.dart';
import 'package:provider/provider.dart' as ctx; // Alias for provider package
import '../services/auth_service.dart'; // To get token for API calls
import './chat_screen.dart'; // For chat navigation
import './create_booking_screen.dart'; // For booking navigation
import '../l10n/app_localizations.dart';
import '../utils/service_type_localizer.dart';

class ProviderDetailScreen extends StatefulWidget {
  static const routeName = '/provider-detail';

  final String providerId;

  const ProviderDetailScreen({required this.providerId, super.key});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final ApiService _apiService = ApiService();
  Future<Provider?>? _providerFuture; // Nullable as provider might not be found
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = ctx.Provider.of<AuthService>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchProviderDetails();
      }
    });
  }

  Future<void> _fetchProviderDetails() async {
    final authService = ctx.Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication token not found. Please log in.')),
        );
      }
      setState(() {
        _providerFuture =
            Future.error(Exception('Authentication token not found.'));
      });
      return;
    }
    setState(() {
      _providerFuture = _apiService.fetchProviderById(widget.providerId, token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.providerDetails),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Provider?>(
        future: _providerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: _fetchProviderDetails,
                      child: Text(AppLocalizations.of(context)!.retry))
                ],
              ),
            ));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(AppLocalizations.of(context)!.unknownProvider));
          }

          final provider = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: provider.profilePictureUrl != null &&
                            provider.profilePictureUrl!.isNotEmpty &&
                            provider.profilePictureUrl!.startsWith('http')
                        ? NetworkImage(provider.profilePictureUrl!)
                        : const AssetImage('assets/default_user.png') as ImageProvider,
                    child: (provider.profilePictureUrl == null ||
                            provider.profilePictureUrl!.isEmpty)
                        ? Text(
                            provider.fullName?.isNotEmpty == true
                                ? provider.fullName![0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                                fontSize: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Text(
                    provider.fullName ?? 'N/A',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (provider.serviceType != null &&
                    provider.serviceType!.isNotEmpty)
                  Center(
                    child: Text(
                      ServiceTypeLocalizer.getLocalizedServiceType(provider.serviceType, AppLocalizations.of(context)!),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16.0),
                _buildRatingSection(context, provider),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),

                _buildSectionTitle(context, AppLocalizations.of(context)!.serviceDetails),
                _buildDetailRow(context, Icons.work_outline, AppLocalizations.of(context)!.description,
                    provider.serviceDescription ?? AppLocalizations.of(context)!.noDescriptionProvided),
                if (provider.hourlyRate != null)
                  _buildDetailRow(context, Icons.attach_money, AppLocalizations.of(context)!.hourlyRate,
                      '\$${provider.hourlyRate!.toStringAsFixed(2)}/${AppLocalizations.of(context)!.hour}'),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),

                _buildSectionTitle(context, AppLocalizations.of(context)!.locationAndContact),
                _buildDetailRow(context, Icons.location_on_outlined, AppLocalizations.of(context)!.address,
                    provider.location?.addressText ?? AppLocalizations.of(context)!.notSpecified),
                // TODO: Display map if coordinates are available
                // if (provider.location?.coordinates != null && provider.location!.coordinates!.length == 2) ...

                _buildDetailRow(context, Icons.phone_outlined, AppLocalizations.of(context)!.phone,
                    provider.contactInfo?.phone ?? AppLocalizations.of(context)!.notSpecified),
                _buildDetailRow(context, Icons.alternate_email_outlined,
                    AppLocalizations.of(context)!.email, provider.email ?? AppLocalizations.of(context)!.notSpecified),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),

                _buildSectionTitle(context, AppLocalizations.of(context)!.availability),
                _buildDetailRow(
                    context,
                    Icons.access_time_outlined,
                    AppLocalizations.of(context)!.availability,
                    provider.availabilityDetails ?? AppLocalizations.of(context)!.notSpecified),
                const SizedBox(height: 24.0),

                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(AppLocalizations.of(context)!.bookService),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      // Navigate to CreateBookingScreen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateBookingScreen(
                            serviceProvider: provider,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(AppLocalizations.of(context)!.chatWith(provider.fullName ?? AppLocalizations.of(context)!.provider)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            // Create a temporary conversation object to pass to the chat screen
                            final conversation = ChatConversation(
                              id: provider.id ?? 'unknown-provider', // Use provider ID as a temporary unique ID
                              participantId: provider.id ?? 'unknown-provider',
                              participantName: provider.fullName ?? 'Provider',
                              participantAvatar: provider.profilePictureUrl,
                              participantType: 'provider',
                            );
                            return ChatScreen(conversation: conversation);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // TODO: Display Reviews Section
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, Provider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (provider.averageRating != null && provider.averageRating! > 0) ...[
          Icon(Icons.star, color: Colors.amber[600], size: 28),
          const SizedBox(width: 8),
          Text(
            '${provider.averageRating!.toStringAsFixed(1)} ',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '(${provider.totalRatings} ${AppLocalizations.of(context)!.ratingsText})',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.grey[600]),
          ),
        ] else
          Text(
            AppLocalizations.of(context)!.noRatingsYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic, color: Colors.grey[600]),
          ),
      ],
    );
  }
}
