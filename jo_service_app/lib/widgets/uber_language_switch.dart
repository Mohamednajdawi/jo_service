import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';

/// Uber-style floating language switch that appears in the bottom corner
class UberLanguageSwitch extends StatefulWidget {
  final EdgeInsets? margin;
  final bool showOnlyIcon;
  
  const UberLanguageSwitch({
    super.key,
    this.margin,
    this.showOnlyIcon = false,
  });

  @override
  State<UberLanguageSwitch> createState() => _UberLanguageSwitchState();
}

class _UberLanguageSwitchState extends State<UberLanguageSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Positioned(
      bottom: widget.margin?.bottom ?? 20,
      right: localeService.isRTL ? null : (widget.margin?.right ?? 20),
      left: localeService.isRTL ? (widget.margin?.left ?? 20) : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(widget.showOnlyIcon ? 25 : 30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(widget.showOnlyIcon ? 25 : 30),
                    onTapDown: (_) => _animationController.forward(),
                    onTapUp: (_) => _animationController.reverse(),
                    onTapCancel: () => _animationController.reverse(),
                    onTap: () => _handleLanguageSwitch(context, localeService),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.showOnlyIcon ? 12 : 16,
                        vertical: widget.showOnlyIcon ? 12 : 12,
                      ),
                      child: widget.showOnlyIcon 
                          ? _buildIconOnly(context, localeService)
                          : _buildWithText(context, localeService),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconOnly(BuildContext context, LocaleService localeService) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          localeService.currentLocale.languageCode.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWithText(BuildContext context, LocaleService localeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              localeService.currentLocale.languageCode.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          localeService.currentLocaleDisplayName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _handleLanguageSwitch(BuildContext context, LocaleService localeService) {
    // Show bottom sheet with language options (Uber style)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => UberLanguageBottomSheet(),
    );
  }
}

/// Uber-style language selection bottom sheet
class UberLanguageBottomSheet extends StatelessWidget {
  const UberLanguageBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    l10n.changeLanguage,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Language options
            ...LocaleService.supportedLocales.map((locale) {
              final isSelected = localeService.currentLocale == locale;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      locale.languageCode.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  localeService.getLocaleDisplayName(locale),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected 
                    ? Icon(
                        Icons.check,
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
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Stack wrapper that adds Uber-style language switch to any screen
class WithUberLanguageSwitch extends StatelessWidget {
  final Widget child;
  final bool showOnlyIcon;
  final EdgeInsets? languageButtonMargin;
  
  const WithUberLanguageSwitch({
    super.key,
    required this.child,
    this.showOnlyIcon = false,
    this.languageButtonMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        UberLanguageSwitch(
          showOnlyIcon: showOnlyIcon,
          margin: languageButtonMargin,
        ),
      ],
    );
  }
} 