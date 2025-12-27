import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, defaultTargetPlatform;
import 'package:flutter/services.dart' show TargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/firebase/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'auth/auth_controller.dart';
import 'auth/ui/welcome_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Connecter aux emulators Firebase en mode debug/local
  if (kDebugMode) {
    await _connectToFirebaseEmulators();
  }
  
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
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    
    if (kDebugMode) {
      print('✅ Connecté aux emulators Firebase locaux');
      print('   - Host: $host');
      print('   - Auth: $host:9099');
      print('   - Firestore: $host:8080');
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
      home: const AuthWrapper(),
      routes: {
        AppRoutes.home: (context) => const ProfilePage(),
        AppRoutes.profile: (context) => const ProfilePage(),
      },
      onGenerateRoute: (settings) {
        // Handle routes that need parameters
        switch (settings.name) {
          case AppRoutes.home:
          case AppRoutes.profile:
            return MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            );
          default:
            return null;
        }
      },
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    _authController.authService.authStateChanges.listen((User? user) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    if (_authController.currentUser != null) {
      // User is logged in, show home
      return const ProfilePage(); // Replace with your home page
    } else {
      // User is not logged in, show welcome
      return WelcomePage(authController: _authController);
    }
  }
}

