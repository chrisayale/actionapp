import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/firebase/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/widgets/initial_route_guard.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Action App Admin',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.initial,
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          // Si la route n'existe pas, rediriger vers la page de garde
          if (!AppRoutes.routes.containsKey(settings.name)) {
            return MaterialPageRoute(
              builder: (context) => InitialRouteGuard(),
            );
          }
          return null;
        },
      ),
    );
  }
}

