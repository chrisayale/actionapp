import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Page d'abonnement pour les annonceurs
/// Permet de choisir entre différents types d'abonnements
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? _selectedSubscriptionType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondaryLight,
      appBar: AppBar(
        title: Text(
          'Abonnements',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Choisissez votre abonnement',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sélectionnez le type d\'abonnement qui correspond à vos besoins',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Liste des abonnements
            ..._buildSubscriptionTypes(),
            const SizedBox(height: AppSpacing.xl),
            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSubscriptionType != null ? _handleSubscribe : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowPrimary,
                  foregroundColor: AppColors.textPrimaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'S\'abonner',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubscriptionTypes() {
    return [
      _buildSubscriptionCard(
        type: 'basic',
        title: 'Abonnement de base',
        description: 'Abonnement essentiel pour promouvoir vos produits',
        price: '50 000 CDF',
        period: '/mois',
        features: [
          'Jusqu\'à 10 promotions actives',
          'Statistiques de base',
          'Support par email',
        ],
        icon: Icons.star_outline_rounded,
        color: AppColors.info,
      ),
      const SizedBox(height: AppSpacing.md),
      _buildSubscriptionCard(
        type: 'premium',
        title: 'Abonnement Premium',
        description: 'Pour les établissements qui veulent maximiser leur visibilité',
        price: '100 000 CDF',
        period: '/mois',
        features: [
          'Promotions illimitées',
          'Statistiques détaillées',
          'Support prioritaire',
          'Promotion en vedette',
        ],
        icon: Icons.diamond_outlined,
        color: AppColors.yellowPrimary,
        isPopular: true,
      ),
      const SizedBox(height: AppSpacing.md),
      _buildSubscriptionCard(
        type: 'banner',
        title: 'Abonnement Bannière',
        description: 'Affichez votre bannière dans le carousel principal',
        price: '150 000 CDF',
        period: '/mois',
        features: [
          'Toutes les fonctionnalités Premium',
          'Bannière personnalisée dans le carousel',
          'Visibilité maximale',
          'Design personnalisé',
        ],
        icon: Icons.campaign_rounded,
        color: AppColors.success,
        showBannerUpload: true,
      ),
    ];
  }

  Widget _buildSubscriptionCard({
    required String type,
    required String title,
    required String description,
    required String price,
    required String period,
    required List<String> features,
    required IconData icon,
    required Color color,
    bool isPopular = false,
    bool showBannerUpload = false,
  }) {
    final isSelected = _selectedSubscriptionType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubscriptionType = type;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec badge populaire
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryLight,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Populaire',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.yellowPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checkbox de sélection
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : AppColors.gray400,
                        width: 2,
                      ),
                      color: isSelected ? color : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Prix
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: AppColors.gray200, height: 1),
              const SizedBox(height: AppSpacing.md),
              // Liste des fonctionnalités
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              // Upload de bannière (si applicable)
              if (showBannerUpload && isSelected) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.gray200, height: 1),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Bannière personnalisée',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'upload de bannière
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fonctionnalité d\'upload de bannière à venir'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text('Télécharger une bannière'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubscribe() {
    if (_selectedSubscriptionType == null) return;

    // TODO: Implémenter la logique d'abonnement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abonnement "$_selectedSubscriptionType" sélectionné. Fonctionnalité à venir.'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }
}



