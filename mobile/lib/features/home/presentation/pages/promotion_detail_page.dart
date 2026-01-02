import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../advertiser/data/models/promotion_model.dart';

class PromotionDetailPage extends StatelessWidget {
  final PromotionModel promotion;

  const PromotionDetailPage({
    super.key,
    required this.promotion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar avec image en arrière-plan
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: AppColors.yellowPrimary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimaryLight,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fond jaune avec gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.yellowPrimary,
                          AppColors.yellowPrimary.withOpacity(0.8),
                          AppColors.yellowDark,
                        ],
                      ),
                    ),
                  ),
                  // Image de marque ou enseigne de l'établissement au centre
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: promotion.establishmentLogoUrl != null && promotion.establishmentLogoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                promotion.establishmentLogoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.store_rounded,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  // Gradient overlay léger en bas
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenu principal
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card principale avec les informations
                Container(
                  margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec nom de l'établissement et logo
                      Row(
                        children: [
                          if (promotion.establishmentLogoUrl != null && promotion.establishmentLogoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                promotion.establishmentLogoUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.store_rounded,
                                      color: AppColors.gray500,
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.gray200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                color: AppColors.gray500,
                              ),
                            ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promotion.establishmentName,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryLight,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Badge statut
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: promotion.isUnlimited
                                            ? AppColors.info.withOpacity(0.15)
                                            : promotion.isActive
                                                ? AppColors.success.withOpacity(0.15)
                                                : AppColors.gray300.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: promotion.isUnlimited
                                                  ? AppColors.info
                                                  : promotion.isActive
                                                      ? AppColors.success
                                                      : AppColors.gray500,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            promotion.isUnlimited
                                                ? 'Sans limite'
                                                : promotion.isActive
                                                    ? 'Active'
                                                    : 'Inactive',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: promotion.isUnlimited
                                                  ? AppColors.info
                                                  : promotion.isActive
                                                      ? AppColors.success
                                                      : AppColors.gray600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Séparateur
                      Divider(color: AppColors.gray200, height: 1),
                      const SizedBox(height: AppSpacing.xl),
                      // Informations de localisation
                      if (promotion.location != null) ...[
                        _buildDetailSection(
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.info,
                          title: 'Localisation',
                          children: [
                            if (promotion.location!.ville != null && promotion.location!.ville!.isNotEmpty)
                              _buildDetailRow('Ville', promotion.location!.ville!),
                            if (promotion.location!.quartier != null && promotion.location!.quartier!.isNotEmpty)
                              _buildDetailRow('Quartier/Commune', promotion.location!.quartier!),
                            if (promotion.location!.avenue != null && promotion.location!.avenue!.isNotEmpty)
                              _buildDetailRow('Avenue', promotion.location!.avenue!),
                            if (promotion.location!.numero != null && promotion.location!.numero!.isNotEmpty)
                              _buildDetailRow('Numéro', promotion.location!.numero!),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Informations de la promotion
                      _buildDetailSection(
                        icon: Icons.local_offer_rounded,
                        iconColor: AppColors.yellowPrimary,
                        title: 'Détails de la promotion',
                        children: [
                          _buildDetailRow('Boisson', promotion.boissonName),
                          _buildDetailRow('Formule', promotion.formule),
                          if (promotion.price != null)
                            _buildDetailRow(
                              'Prix',
                              '${promotion.price!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} ${promotion.currency ?? ''}',
                            ),
                          if (promotion.isUnlimited)
                            _buildDetailRow('Durée', 'Promotion continue (sans limite)')
                          else
                            _buildDetailRow(
                              'Période',
                              'Du ${_formatDate(promotion.startDate)} au ${_formatDate(promotion.endDate)}',
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Statistiques
                      _buildDetailSection(
                        icon: Icons.bar_chart_rounded,
                        iconColor: AppColors.success,
                        title: 'Statistiques',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.visibility_rounded,
                                  label: 'Vues',
                                  value: _formatCount(promotion.viewCount),
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.favorite_rounded,
                                  label: 'Intéressés',
                                  value: _formatCount(promotion.interestedCount),
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Boutons d'action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                  child: Column(
                    children: [
                      // Bouton Voir itinéraire
                      if (promotion.location != null && promotion.location!.latitude != null && promotion.location!.longitude != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openMaps(context, promotion.location!),
                            icon: const Icon(Icons.directions_rounded, size: 22),
                            label: Text(
                              'Voir itinéraire',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      if (promotion.location != null && promotion.location!.latitude != null && promotion.location!.longitude != null)
                        const SizedBox(height: AppSpacing.md),
                      // Bouton Chat
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implémenter le chat
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fonctionnalité de chat à venir'),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                          label: Text(
                            'Chat',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: const BorderSide(color: AppColors.info, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
  }

  Future<void> _openMaps(BuildContext context, PromotionLocation location) async {
    if (location.latitude == null || location.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localisation non disponible'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir Google Maps';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de la carte: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

