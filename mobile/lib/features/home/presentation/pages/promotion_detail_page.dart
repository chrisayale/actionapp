import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../advertiser/data/models/promotion_model.dart';
import '../../../advertiser/data/repositories/advertiser_repository.dart';

class PromotionDetailPage extends StatefulWidget {
  final PromotionModel promotion;

  const PromotionDetailPage({
    super.key,
    required this.promotion,
  });

  @override
  State<PromotionDetailPage> createState() => _PromotionDetailPageState();
}

class _PromotionDetailPageState extends State<PromotionDetailPage> {
  final AdvertiserRepository _repository = AdvertiserRepository();
  bool _hasIncrementedView = false;

  @override
  void initState() {
    super.initState();
    // Incrémenter le compteur de vues quand la page est ouverte
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    // Ne pas incrémenter plusieurs fois si la page est reconstruite
    if (!_hasIncrementedView) {
      _hasIncrementedView = true;
      await _repository.incrementViewCount(widget.promotion.id);
    }
  }

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
                  // Image du produit/boisson en promotion au centre avec son nom
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: widget.promotion.boissonImageUrl != null && widget.promotion.boissonImageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.promotion.boissonImageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.local_drink,
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
                                    Icons.local_drink,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Nom du produit/boisson
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            widget.promotion.boissonName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                // Section avec image de l'enseigne en fond jaune
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.screenHorizontal),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.yellowPrimary,
                        AppColors.yellowPrimary.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: widget.promotion.establishmentLogoUrl != null && widget.promotion.establishmentLogoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.promotion.establishmentLogoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.store_rounded,
                                      size: 60,
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
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
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
                          if (widget.promotion.establishmentLogoUrl != null && widget.promotion.establishmentLogoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.promotion.establishmentLogoUrl!,
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
                                  widget.promotion.establishmentName,
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
                                        color: widget.promotion.isUnlimited
                                            ? AppColors.info.withOpacity(0.15)
                                            : widget.promotion.isActive
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
                                              color: widget.promotion.isUnlimited
                                                  ? AppColors.info
                                                  : widget.promotion.isActive
                                                      ? AppColors.success
                                                      : AppColors.gray500,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.promotion.isUnlimited
                                                ? 'Sans limite'
                                                : widget.promotion.isActive
                                                    ? 'Active'
                                                    : 'Inactive',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: widget.promotion.isUnlimited
                                                  ? AppColors.info
                                                  : widget.promotion.isActive
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
                      if (widget.promotion.location != null) ...[
                        _buildDetailSection(
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.info,
                          title: 'Localisation',
                          children: [
                            if (widget.promotion.location!.ville != null && widget.promotion.location!.ville!.isNotEmpty)
                              _buildDetailRow('Ville', widget.promotion.location!.ville!),
                            if (widget.promotion.location!.quartier != null && widget.promotion.location!.quartier!.isNotEmpty)
                              _buildDetailRow('Quartier/Commune', widget.promotion.location!.quartier!),
                            if (widget.promotion.location!.avenue != null && widget.promotion.location!.avenue!.isNotEmpty)
                              _buildDetailRow('Avenue', widget.promotion.location!.avenue!),
                            if (widget.promotion.location!.numero != null && widget.promotion.location!.numero!.isNotEmpty)
                              _buildDetailRow('Numéro', widget.promotion.location!.numero!),
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
                          _buildDetailRow('Boisson', widget.promotion.boissonName),
                          _buildDetailRow('Formule', widget.promotion.formule),
                          if (widget.promotion.price != null)
                            _buildDetailRow(
                              'Prix',
                              '${widget.promotion.price!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} ${widget.promotion.currency ?? ''}',
                            ),
                          if (widget.promotion.isUnlimited)
                            _buildDetailRow('Durée', 'Promotion continue (sans limite)')
                          else
                            _buildDetailRow(
                              'Période',
                              'Du ${_formatDate(widget.promotion.startDate)} au ${_formatDate(widget.promotion.endDate)}',
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
                                  value: _formatCount(widget.promotion.viewCount),
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.favorite_rounded,
                                  label: 'Intéressés',
                                  value: _formatCount(widget.promotion.interestedCount),
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
                      // Bouton Voir itinéraire - Toujours affiché
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.promotion.location != null && 
                                widget.promotion.location!.latitude != null && 
                                widget.promotion.location!.longitude != null) {
                              _openMaps(context, widget.promotion.location!);
                            } else if (widget.promotion.location != null) {
                              // Si on a une adresse mais pas de coordonnées, ouvrir Google Maps avec l'adresse
                              _openMapsWithAddress(context, widget.promotion.location!);
                            } else {
                              // Aucune localisation disponible
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Localisation non disponible pour cette promotion'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                          },
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
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
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

  Future<void> _openMapsWithAddress(BuildContext context, PromotionLocation location) async {
    // Construire l'adresse à partir des informations disponibles
    final addressParts = <String>[];
    if (location.numero != null && location.numero!.isNotEmpty) {
      addressParts.add(location.numero!);
    }
    if (location.avenue != null && location.avenue!.isNotEmpty) {
      addressParts.add(location.avenue!);
    }
    if (location.quartier != null && location.quartier!.isNotEmpty) {
      addressParts.add(location.quartier!);
    }
    if (location.ville != null && location.ville!.isNotEmpty) {
      addressParts.add(location.ville!);
    }

    if (addressParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adresse non disponible'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final address = addressParts.join(', ');
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
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

