import '../l10n/app_localizations.dart';

/// Utility class for translating service types from English to localized versions
class ServiceTypeLocalizer {
  /// Translates a service type string to the appropriate localized version
  static String getLocalizedServiceType(String? serviceType, AppLocalizations l10n) {
    if (serviceType == null) return l10n.unknown;
    
    switch (serviceType.toLowerCase()) {
      case 'electrician':
      case 'electrical':
        return l10n.electrical; // Use service category translation
      case 'plumber':
      case 'plumbing':
        return l10n.plumbing; // Use service category translation
      case 'painter':
      case 'painting':
        return l10n.painting; // Use service category translation
      case 'cleaner':
      case 'cleaning':
        return l10n.cleaning; // Use service category translation
      case 'carpenter':
      case 'carpentry':
        return l10n.carpentry; // Use service category translation
      case 'gardener':
      case 'gardening':
        return l10n.gardening; // Use service category translation
      case 'mechanic':
        return l10n.mechanic;
      case 'air conditioning technician':
      case 'airconditioning':
      case 'air_conditioning':
        return l10n.airConditioningTechnician;
      case 'general maintenance':
      case 'maintenance':
        return l10n.generalMaintenance;
      case 'housekeeper':
        return l10n.housekeeper;
      default:
        return serviceType; // Return original if no translation found
    }
  }
}
