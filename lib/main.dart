// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/language_service.dart';
import 'core/services/favorites_service.dart';
import 'core/services/daily_targets_service.dart';
import 'core/services/leaderboard_service.dart';
import 'core/services/certificate_service.dart';
import 'core/services/streak_service.dart';
import 'core/services/deity_service.dart';
import 'core/services/mantra_service.dart';
import 'core/services/leaderboard_certificate_service.dart';

import 'core/services/puja_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/fcm_token_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/in_app_update_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/dharma_store/services/cart_service.dart';
import 'features/dharma_store/services/store_service.dart';
import 'core/services/pandit_package_service.dart';
import 'core/services/pandit_package_order_service.dart';
import 'core/services/pandit_service.dart';
import 'features/astro/viewmodels/astrologer_viewmodel.dart';
import 'features/festival_kit/viewmodels/festival_viewmodel.dart';
import 'core/providers/panchang_provider.dart';
import 'core/providers/festival_provider.dart';
import 'core/services/user_home_service.dart';
import 'features/teacher/viewmodel/teacher_viewmodel.dart';
import 'features/auth/login.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/home/home.dart';
import 'features/mantra_generator/viewmodels/problem_list_viewmodel.dart';
import 'features/mantra_generator/viewmodels/credit_viewmodel.dart';
import 'features/onboarding/views/onboarding_screen.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for Razorpay keys etc.
  await dotenv.load(fileName: "assets/.env");

  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    runApp(const AppBootstrap());
  }, (error, stack) {
  });
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Future<void>? _fullInitFuture;
  bool _showOnboardingFirst = false;
  bool _minimalReady = false;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    if (!mounted) return;

    // Always show onboarding first on every launch (even if user skipped before)
    setState(() {
      _showOnboardingFirst = true;
      _minimalReady = true;
    });
  }

  Future<void> _initializeApp() async {
    await Firebase.initializeApp().timeout(const Duration(seconds: 15));

    FirebaseMessaging.onBackgroundMessage(
      NotificationService.handleBackgroundMessage,
    );
    try {
      await NotificationService.initialize()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
    }

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    ).timeout(const Duration(seconds: 15));

    await CacheService.initialize().timeout(const Duration(seconds: 5));

    // Load deities and panchang after user reaches home/signup
    unawaited(DeityService.initializeDeities());
  }

  void _onOnboardingComplete() async {
    if (!mounted) return;

    setState(() {
      _showOnboardingFirst = false;
      _fullInitFuture = _initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Show onboarding first (first-time users)
    if (_showOnboardingFirst && _minimalReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
        ),
        home: _MinimalOnboardingScreen(onFinish: _onOnboardingComplete),
      );
    }

    // Phase 2: Full init in progress (after onboarding or returning user)
    if (_fullInitFuture != null) {
      return FutureBuilder<void>(
        future: _fullInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.error == null) {
            return const MyApp(skipOnboarding: true);
          }
          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: _BootstrapError(
                error: snapshot.error,
                onRetry: () {
                  setState(() {
                    _fullInitFuture = _initializeApp();
                  });
                },
              ),
            );
          }
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootstrapLoading(),
          );
        },
      );
    }

    // Phase 0: Very brief - checking route (show splash/loading)
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootstrapLoading(),
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _DharmicLoadingIndicator(),
      ),
    );
  }
}

class _DharmicLoadingIndicator extends StatelessWidget {
  const _DharmicLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: CircularProgressIndicator(
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: Colors.orange.shade600,
              backgroundColor: Colors.orange.shade100,
            ),
          ),

          Text(
            "ॐ",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 90, // proportional to 190 size
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}



class _BootstrapError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _BootstrapError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text(
                'App failed to initialize',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal onboarding screen - no Firebase/Supabase, loads instantly
class _MinimalOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const _MinimalOnboardingScreen({required this.onFinish});

  @override
  State<_MinimalOnboardingScreen> createState() =>
      _MinimalOnboardingScreenState();
}

class _MinimalOnboardingScreenState extends State<_MinimalOnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(onFinish: widget.onFinish);
  }
}

class MyApp extends StatelessWidget {
  final bool skipOnboarding;

  const MyApp({super.key, this.skipOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => LanguageService()),
        ChangeNotifierProvider(create: (context) => FavoritesService()),
        ChangeNotifierProvider(create: (context) => DailyTargetsService()),
        ChangeNotifierProvider(create: (context) => LeaderboardService()),
        ChangeNotifierProvider(create: (context) => CertificateService()),
        ChangeNotifierProvider(
          create: (context) => LeaderboardCertificateService(),
        ),
        ChangeNotifierProvider(create: (context) => StreakService()),

        // Mantra & Deity Services
        Provider(create: (context) => DeityService()),
        Provider(create: (context) => MantraService()),

        Provider(create: (context) => PujaService()),
        Provider(create: (context) => PaymentService()),
        ChangeNotifierProvider(create: (context) => CartService()),
        Provider(create: (context) => StoreService()),
        Provider(create: (context) => PanditPackageService()),
        Provider(create: (context) => PanditPackageOrderService()),
        Provider(create: (context) => PanditService()),
        ChangeNotifierProvider(create: (context) => AstrologerViewModel()),
        ChangeNotifierProvider(create: (context) => FestivalViewModel()),
        ChangeNotifierProvider(create: (context) => PanchangProvider()),
        ChangeNotifierProvider(create: (context) => FestivalProvider()),
        Provider(create: (context) => UserHomeService()),
        ChangeNotifierProvider(create: (context) => TeacherViewModel()),
        ChangeNotifierProvider(create: (context) => ProblemListViewModel()),
        ChangeNotifierProvider(create: (context) => CreditViewModel()),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'Karmasu',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            locale: languageService.currentLocale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US'), Locale('hi', 'IN')],
            home: skipOnboarding
                ? const AuthWrapper()
                : const OnboardingGate(),
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return const AuthWrapper();
    }

    return OnboardingScreen(
      onFinish: () {
        setState(() {
          _completed = true;
        });
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for updates after a short delay to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        InAppUpdateService.checkForUpdate(context);
      });
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      unawaited(FcmTokenService.registerUserToken());
      FcmTokenService.startUserTokenRefreshListener();
    }

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        unawaited(FcmTokenService.registerUserToken());
        FcmTokenService.startUserTokenRefreshListener();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Update token when app is opened/resumed if user is logged in
      if (Supabase.instance.client.auth.currentUser != null) {
        unawaited(FcmTokenService.registerUserToken());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final event = snapshot.data!.event;
          if (event == AuthChangeEvent.passwordRecovery) {
            // Extract email from session
            final email = snapshot.data!.session?.user.email ?? '';
            return ResetPasswordScreen(email: email);
          }
        }

        // When we have auth data, use it
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return const HomeScreen();
          }
          return const LoginScreen(isSignUp: true);
        }

        // While waiting: show LoginScreen immediately (typical after onboarding)
        // Stream will update to HomeScreen if session exists
        if (authService.isAuthenticated()) {
          return const HomeScreen();
        }
        return const LoginScreen(isSignUp: true);
      },
    );
  }
}
