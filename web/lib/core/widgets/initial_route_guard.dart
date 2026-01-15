import 'package:flutter/material.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/create_super_admin_page.dart';
import '../routes/app_routes.dart';

class InitialRouteGuard extends StatefulWidget {
  const InitialRouteGuard({super.key});

  @override
  State<InitialRouteGuard> createState() => _InitialRouteGuardState();
}

class _InitialRouteGuardState extends State<InitialRouteGuard> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isChecking = true;
  bool _hasAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminExists();
  }

  Future<void> _checkAdminExists() async {
    try {
      final hasAdmin = await _authRepository.hasAdmin();
      print('Vérification admin: hasAdmin = $hasAdmin');
      
      if (!mounted) return;
      
      // Si un admin existe, rediriger immédiatement vers la page de login
      if (hasAdmin) {
        print('Admin trouvé, redirection vers login...');
        // Utiliser un petit délai pour s'assurer que le contexte est prêt
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }
      
      // Si aucun admin, mettre à jour l'état pour afficher la page de création
      print('Aucun admin trouvé, affichage de la page de création');
      if (mounted) {
        setState(() {
          _hasAdmin = false;
          _isChecking = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      // En cas d'erreur, on assume qu'il n'y a pas d'admin
      if (mounted) {
        setState(() {
          _hasAdmin = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade700,
                Colors.indigo.shade900,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // Si un admin existe, on ne devrait jamais arriver ici car la redirection
    // se fait dans _checkAdminExists(). Mais au cas où, afficher un loader
    if (_hasAdmin) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade700,
                Colors.indigo.shade900,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // Si aucun admin n'existe, afficher la page de création
    return const CreateSuperAdminPage();
  }
}
