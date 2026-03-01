import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final bool showAsBottomSheet;
  
  const LanguageSelector({
    super.key,
    this.showAsBottomSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showAsBottomSheet) {
      return _buildBottomSheet(context);
    }
    return _buildListTile(context);
  }

  Widget _buildListTile(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(localeService.currentLocaleDisplayName),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showLanguageBottomSheet(context),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context);
    
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.changeLanguage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Language options
          ...LocaleService.supportedLocales.map((locale) {
            final isSelected = localeService.currentLocale == locale;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[200],
                child: Text(
                  locale.languageCode.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                localeService.getLocaleDisplayName(locale),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected 
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              onTap: () async {
                await localeService.changeLocale(locale);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const LanguageSelector(showAsBottomSheet: true),
      ),
    );
  }
}

// Quick language toggle button (like Uber's floating language button)
class LanguageToggleButton extends StatelessWidget {
  final EdgeInsets? margin;
  
  const LanguageToggleButton({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: FloatingActionButton.small(
        heroTag: "language_toggle",
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 2,
        onPressed: () => localeService.toggleLocale(),
        child: Text(
          localeService.currentLocale.languageCode.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Animated language switch button
class AnimatedLanguageSwitch extends StatefulWidget {
  const AnimatedLanguageSwitch({super.key});

  @override
  State<AnimatedLanguageSwitch> createState() => _AnimatedLanguageSwitchState();
}

class _AnimatedLanguageSwitchState extends State<AnimatedLanguageSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: () async {
        _controller.forward().then((_) {
          localeService.toggleLocale();
          _controller.reverse();
        });
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_animation.value * 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localeService.currentLocaleDisplayName,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 