import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../auth/auth_controller.dart';

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
    );
  }

  Widget _buildBody() {
    if (_establishments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshEstablishments,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun établissement',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ajoutez votre premier établissement',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to add establishment screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à venir'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un établissement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowPrimary,
              foregroundColor: AppColors.textPrimaryLight,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshEstablishments() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  void _handleManage(Establishment establishment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gérer: ${establishment.name}'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Navigate to management screen
  }

  void _handleEdit(Establishment establishment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modifier: ${establishment.name}'),
        backgroundColor: AppColors.info,
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
        content: Text(
          establishment.isActive
              ? '${establishment.name} désactivé'
              : '${establishment.name} activé',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
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
        title: Text(
          'Supprimer l\'établissement',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${establishment.name}" ?\n\nCette action est irréversible.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
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
          content: Text('${establishment.name} supprimé'),
          backgroundColor: AppColors.success,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Establishment icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.yellowPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppColors.yellowPrimary,
                      size: 24,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textTertiaryLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                establishment.location,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiaryLight,
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
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: establishment.isActive
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.gray300.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
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
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          establishment.isActive ? 'Actif' : 'Inactif',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: establishment.isActive
                                ? AppColors.success
                                : AppColors.gray600,
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
              thickness: 1,
              color: AppColors.gray200,
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
                      icon: Icons.settings,
                      label: 'Gérer',
                      color: AppColors.info,
                      onPressed: onManage,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Modifier button
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit,
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
                          ? Icons.toggle_on
                          : Icons.toggle_off,
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
                      icon: Icons.delete_outline,
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

