import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../auth/auth_controller.dart';
import 'create_advertiser_page.dart';

/// Screen for managing advertiser establishments
/// Displays a list of establishments with actions: Manage, Edit, Toggle Status, Delete
class AdvertiserManagementPage extends StatefulWidget {
  final AuthController authController;

  const AdvertiserManagementPage({
    super.key,
    required this.authController,
  });

  @override
  State<AdvertiserManagementPage> createState() => _AdvertiserManagementPageState();
}

class _AdvertiserManagementPageState extends State<AdvertiserManagementPage> {
  // Mock data for establishments
  List<Establishment> _establishments = [
    Establishment(
      id: '1',
      name: 'RDC BAR',
      location: 'KAVA/GOMBE, Kinshasa',
      isActive: true,
    ),
    Establishment(
      id: '2',
      name: 'Bistro Le Soleil d\'Or',
      location: 'GOMBE, Kinshasa',
      isActive: true,
    ),
    Establishment(
      id: '3',
      name: 'Café Central',
      location: 'LINGWALA, Kinshasa',
      isActive: false,
    ),
    Establishment(
      id: '4',
      name: 'Restaurant La Terrasse',
      location: 'GOMBE, Kinshasa',
      isActive: true,
    ),
    Establishment(
      id: '5',
      name: 'Night Club VIP',
      location: 'MAKALA, Kinshasa',
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          'Annonceurs',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellowPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _handleCreateAdvertiser(),
          backgroundColor: AppColors.yellowPrimary,
          foregroundColor: AppColors.textPrimaryLight,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: Text(
            'Créer un annonceur',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_establishments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshEstablishments,
      color: AppColors.yellowPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        itemCount: _establishments.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _EstablishmentListItem(
              establishment: _establishments[index],
              onManage: () => _handleManage(_establishments[index]),
              onEdit: () => _handleEdit(_establishments[index]),
              onToggleStatus: () => _handleToggleStatus(_establishments[index]),
              onDelete: () => _handleDelete(_establishments[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.yellowPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_outlined,
                size: 80,
                color: AppColors.yellowPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Aucun établissement',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Commencez par ajouter votre premier établissement',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _handleCreateAdvertiser(),
              icon: const Icon(Icons.add_circle_outline, size: 24),
              label: const Text('Ajouter un établissement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellowPrimary,
                foregroundColor: AppColors.textPrimaryLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshEstablishments() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  void _handleCreateAdvertiser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAdvertiserPage(
          authController: widget.authController,
        ),
      ),
    ).then((result) {
      // Refresh the list if an advertiser was created
      if (result == true) {
        _refreshEstablishments();
      }
    });
  }

  void _handleManage(Establishment establishment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.settings, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gérer: ${establishment.name}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
    // TODO: Navigate to management screen
  }

  void _handleEdit(Establishment establishment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.edit, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Modifier: ${establishment.name}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
    // TODO: Navigate to edit screen
  }

  void _handleToggleStatus(Establishment establishment) {
    setState(() {
      final index = _establishments.indexWhere((e) => e.id == establishment.id);
      if (index != -1) {
        _establishments[index] = Establishment(
          id: establishment.id,
          name: establishment.name,
          location: establishment.location,
          isActive: !establishment.isActive,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              establishment.isActive ? Icons.check_circle : Icons.pause_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                establishment.isActive
                    ? '${establishment.name} désactivé'
                    : '${establishment.name} activé',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }

  Future<void> _handleDelete(Establishment establishment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Supprimer',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${establishment.name}" ?\n\nCette action est irréversible.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondaryLight,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              elevation: 0,
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _establishments.removeWhere((e) => e.id == establishment.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${establishment.name} supprimé',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          action: SnackBarAction(
            label: 'Annuler',
            textColor: AppColors.white,
            onPressed: () {
              // Restore establishment
              setState(() {
                _establishments.add(establishment);
              });
            },
          ),
        ),
      );
    }
  }
}

/// Model class for an establishment
class Establishment {
  final String id;
  final String name;
  final String location;
  final bool isActive;

  Establishment({
    required this.id,
    required this.name,
    required this.location,
    required this.isActive,
  });
}

/// Reusable widget for establishment list item
/// Displays establishment info and action buttons
class _EstablishmentListItem extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback onManage;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _EstablishmentListItem({
    required this.establishment,
    required this.onManage,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.gray200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and status
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Establishment icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.yellowPrimary,
                        AppColors.yellowPrimary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellowPrimary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Name and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        establishment.name,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              establishment.location,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textTertiaryLight,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: establishment.isActive
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.gray300.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall + 2),
                    border: Border.all(
                      color: establishment.isActive
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.gray400.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: establishment.isActive
                              ? AppColors.success
                              : AppColors.gray500,
                          shape: BoxShape.circle,
                          boxShadow: establishment.isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        establishment.isActive ? 'Actif' : 'Inactif',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: establishment.isActive
                              ? AppColors.success
                              : AppColors.gray600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.gray200,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gérer button
                Expanded(
                  child: _ActionButton(
                    icon: Icons.settings_rounded,
                    label: 'Gérer',
                    color: AppColors.info,
                    onPressed: onManage,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Modifier button
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Modifier',
                    color: AppColors.warning,
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Toggle status button
                Expanded(
                  child: _ActionButton(
                    icon: establishment.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    label: establishment.isActive ? 'Désactiver' : 'Activer',
                    color: establishment.isActive
                        ? AppColors.gray600
                        : AppColors.success,
                    onPressed: onToggleStatus,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Delete button
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Supprimer',
                    color: AppColors.error,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
