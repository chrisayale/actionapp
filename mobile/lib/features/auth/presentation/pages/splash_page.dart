import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(35),
            child: Image.asset(
              'assets/images/Logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              width: 130,
              height: 130,
              errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) {
                  print('❌ Erreur chargement logo: $error');
                }
                // Si le logo ne charge pas, afficher un placeholder très visible
                return Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.apps,
                    size: 100,
                    color: Colors.blue,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

