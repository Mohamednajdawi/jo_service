import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import './user_login_screen.dart';
import './user_home_screen.dart';
import './provider_dashboard_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  static const routeName = '/auth-check';

  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  // Add a variable to store the AuthService instance
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    // Initialize the _authService variable
    _authService = Provider.of<AuthService>(context, listen: false);

    // Use WidgetsBinding.instance.addPostFrameCallback to ensure that
    // the navigation happens after the first frame is built.
    // This is important because AuthService might notify listeners
    // during its initialization, and we need the context to be ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Navigate directly to the UserLoginScreen for now
      Navigator.of(context).pushReplacementNamed(UserLoginScreen.routeName);

      // Uncomment this when you want to implement the full auth flow
      // _checkAuthStatusAndNavigate();
    });
  }

  Future<void> _checkAuthStatusAndNavigate() async {
    // Use the class variable instead of Provider.of
    // If still loading, listen to changes and re-check
    // This scenario might happen if AuthCheckScreen is built before AuthService finishes its async _loadAuthData
    // It's generally better if AuthService completes loading before the app UI that depends on it is shown,
    // but this provides a fallback.
    if (_authService.isLoading) {
      _authService.addListener(_onAuthServiceChanged);
      return; // Exit, _onAuthServiceChanged will handle navigation
    }

    // Once loading is complete, perform the navigation
    _performNavigation(_authService);
  }

  void _onAuthServiceChanged() {
    if (!_authService.isLoading) {
      // Remove listener once loading is done to avoid multiple calls
      _authService.removeListener(_onAuthServiceChanged);
      _performNavigation(_authService);
    }
  }

  void _performNavigation(AuthService authService) {
    if (!mounted) return; // Check if the widget is still in the tree

    if (authService.isAuthenticated) {
      if (authService.userType == 'user') {
        Navigator.of(context).pushReplacementNamed(UserHomeScreen.routeName);
      } else if (authService.userType == 'provider') {
        Navigator.of(context)
            .pushReplacementNamed(ProviderDashboardScreen.routeName);
      } else {
        // Should not happen if userType is always set on login
        Navigator.of(context)
            .pushReplacementNamed(UserLoginScreen.routeName);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(UserLoginScreen.routeName);
    }
  }

  @override
  void dispose() {
    // Clean up listener if the widget is disposed before auth check completes
    // Use the stored instance, which is safe to access in dispose
    _authService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while checking auth status
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
