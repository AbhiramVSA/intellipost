import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'services/services.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/home/view/home_screen.dart';
import 'features/home/viewmodel/home_viewmodel.dart';
import 'features/scan/viewmodel/scan_viewmodel.dart';

/// IntelliPost - Indian Post Letter Scanner App
/// 
/// Architecture: MVVM with Provider for state management
/// 
/// This app allows users to:
/// 1. Scan Indian Post letters using the device camera
/// 2. Send scanned images to a backend API for text extraction
/// 3. View scan history with extracted data
/// 
/// Note: Backend API calls are mocked for development.
/// Replace MockApiService with RealApiService when backend is ready.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final apiService = RealApiService();

  runApp(
    IntelliPostApp(
      storageService: storageService,
      apiService: apiService,
    ),
  );
}

/// Main application widget
class IntelliPostApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;

  const IntelliPostApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    // MultiProvider for dependency injection
    return MultiProvider(
      providers: [
        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),

        // ViewModels
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ScanViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'IntelliPost',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        
        // Route configuration
        initialRoute: '/',
        onGenerateRoute: _generateRoute,
        
        // Home decides initial screen based on login state
        home: const _InitialRouteDecider(),
      ),
    );
  }

  /// Generate routes for named navigation
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const _InitialRouteDecider(),
        );
      case '/login':
        return _buildPageRoute(const LoginScreen(), settings);
      case '/home':
        return _buildPageRoute(const HomeScreen(), settings);
      default:
        return MaterialPageRoute(
          builder: (_) => const _NotFoundScreen(),
        );
    }
  }

  /// Build page route with smooth transition
  PageRoute<T> _buildPageRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Decides initial route based on authentication state
class _InitialRouteDecider extends StatefulWidget {
  const _InitialRouteDecider();

  @override
  State<_InitialRouteDecider> createState() => _InitialRouteDeciderState();
}

class _InitialRouteDeciderState extends State<_InitialRouteDecider> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Small delay for splash effect
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authViewModel = context.read<AuthViewModel>();
    
    if (authViewModel.checkExistingSession()) {
      // User is logged in, go to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User needs to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen while checking auth
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mail_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'IntelliPost',
              style: AppTextStyles.h1.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 404 Not Found Screen
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page does not exist.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
