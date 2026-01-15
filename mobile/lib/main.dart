import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'core/firebase/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'auth/auth_controller.dart';
import 'auth/ui/welcome_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/create_profile_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/advertiser/presentation/pages/advertiser_management_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Utiliser exclusivement Firebase en ligne (production)
  // Les emulators sont désactivés même en mode debug
  // if (kDebugMode) {
  //   await _connectToFirebaseEmulators();
  // }

  runApp(const MyApp());
}

/// Connecte aux emulators Firebase locaux pour le développement
Future<void> _connectToFirebaseEmulators() async {
  try {
    // Détecter la plateforme pour utiliser la bonne adresse
    // Pour Android Emulator, utiliser 10.0.2.2 au lieu de localhost
    // Pour les autres plateformes (iOS, Web, Desktop), utiliser localhost
    String host = 'localhost';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      host = '10.0.2.2'; // Adresse spéciale pour Android Emulator
    }

    // Connecter Auth Emulator
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    // Connecter Firestore Emulator
    FirebaseFirestore.instance.useFirestoreEmulator(host, 9081);

    // Connecter Storage Emulator
    FirebaseStorage.instance.useStorageEmulator(host, 9199);

    if (kDebugMode) {
      print('✅ Connecté aux emulators Firebase locaux');
      print('   - Host: $host');
      print('   - Auth: $host:9099');
      print('   - Firestore: $host:9081');
      print('   - Storage: $host:9199');
      print('');
      print(
        '⚠️  Note: Les emulators Storage peuvent être très lents en développement.',
      );
      print(
        '   Les uploads peuvent prendre plusieurs minutes même pour de petits fichiers.',
      );
      print('   En production, les uploads seront beaucoup plus rapides.');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Erreur lors de la connexion aux emulators: $e');
      print('   Assurez-vous que les emulators Firebase sont démarrés');
      print('   Command: cd firebase && firebase emulators:start');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Action App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      locale: const Locale('fr', 'FR'),
      home: const AuthWrapper(),
      routes: {
        AppRoutes.createProfile: (context) {
          final authWrapperState = context
              .findAncestorStateOfType<_AuthWrapperState>();
          final authController =
              authWrapperState?.authController ?? AuthController();
          return CreateProfilePage(authController: authController);
        },
        AppRoutes.home: (context) {
          // Try to get authController from AuthWrapper, otherwise create new one
          final authWrapperState = context
              .findAncestorStateOfType<_AuthWrapperState>();
          final authController =
              authWrapperState?.authController ?? AuthController();
          return HomePage(authController: authController);
        },
        AppRoutes.profile: (context) {
          final authWrapperState = context
              .findAncestorStateOfType<_AuthWrapperState>();
          final authController =
              authWrapperState?.authController ?? AuthController();
          return ProfilePage(authController: authController);
        },
        AppRoutes.advertiserManagement: (context) {
          final authWrapperState = context
              .findAncestorStateOfType<_AuthWrapperState>();
          final authController =
              authWrapperState?.authController ?? AuthController();
          return AdvertiserManagementPage(authController: authController);
        },
      },
      onGenerateRoute: (settings) {
        // Handle routes that need parameters
        switch (settings.name) {
          case AppRoutes.createProfile:
            return MaterialPageRoute(
              builder: (context) {
                final authWrapperState = context
                    .findAncestorStateOfType<_AuthWrapperState>();
                final authController =
                    authWrapperState?.authController ?? AuthController();
                return CreateProfilePage(authController: authController);
              },
            );
          case AppRoutes.home:
            return MaterialPageRoute(
              builder: (context) {
                final authWrapperState = context
                    .findAncestorStateOfType<_AuthWrapperState>();
                final authController =
                    authWrapperState?.authController ?? AuthController();
                return HomePage(authController: authController);
              },
            );
          case AppRoutes.profile:
            return MaterialPageRoute(
              builder: (context) {
                final authWrapperState = context
                    .findAncestorStateOfType<_AuthWrapperState>();
                final authController =
                    authWrapperState?.authController ?? AuthController();
                return ProfilePage(authController: authController);
              },
            );
          case AppRoutes.advertiserManagement:
            return MaterialPageRoute(
              builder: (context) {
                final authWrapperState = context
                    .findAncestorStateOfType<_AuthWrapperState>();
                final authController =
                    authWrapperState?.authController ?? AuthController();
                return AdvertiserManagementPage(authController: authController);
              },
            );
          default:
            return null;
        }
      },
    );
  }
}

/// Wrapper to handle authentication state with persistent authentication
/// Similar to WhatsApp behavior: checks auth state on launch and redirects accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthController _authController = AuthController();
  bool _isCheckingAuth = true;

  // Expose authController for access from routes
  AuthController get authController => _authController;

  @override
  void initState() {
    super.initState();
    _checkInitialAuthState();
  }

  /// Check authentication state on app launch
  /// This ensures persistent authentication like WhatsApp
  Future<void> _checkInitialAuthState() async {
    // Wait for Firebase Auth to initialize and check current user
    // Firebase Auth persists authentication state automatically
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to listen to auth state changes
    // This ensures we react to auth state changes in real-time
    return StreamBuilder<User?>(
      stream: _authController.authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading screen while checking initial auth state
        if (_isCheckingAuth || snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        // Check if user is authenticated
        final user = snapshot.data ?? _authController.currentUser;
        
        if (user != null) {
          // User is authenticated - go directly to Home
          // This is the persistent auth behavior: skip auth screens
          // No need to check profile completion, always go to Home
          return HomePage(authController: _authController);
        } else {
          // User is NOT authenticated - show welcome/auth screen
          // This is the entry point for new users
          return WelcomePage(authController: _authController);
        }
      },
    );
  }
}

/// Loading screen shown while checking authentication state
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/Logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback si le logo n'est pas trouvé
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFD700),
                            const Color(0xFFFF6B35),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.local_drink,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
