import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/promotion_model.dart';
import 'create_promotion_page.dart';

/// Page displaying a list of promotions for an establishment
class PromotionsListPage extends StatefulWidget {
  final String establishmentId;
  final String establishmentName;
  final String? establishmentLogoUrl;
  final String? enseigneUrl;

  const PromotionsListPage({
    super.key,
    required this.establishmentId,
    required this.establishmentName,
    this.establishmentLogoUrl,
    this.enseigneUrl,
  });

  @override
  State<PromotionsListPage> createState() => _PromotionsListPageState();
}

class _PromotionsListPageState extends State<PromotionsListPage> {
  List<PromotionModel> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load promotions from API/Repository
    // For now, using mock data
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _promotions = _getMockPromotions();
      _isLoading = false;
    });
  }

  List<PromotionModel> _getMockPromotions() {
    // Mock data - replace with actual API call
    return [
      PromotionModel(
        id: '1',
        establishmentId: widget.establishmentId,
        establishmentName: widget.establishmentName,
        establishmentLogoUrl: widget.establishmentLogoUrl,
        boissonId: '1',
        boissonName: 'Primus 72cl',
        formule: '2+1=3',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        isActive: true,
        isUnlimited: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PromotionModel(
        id: '2',
        establishmentId: widget.establishmentId,
        establishmentName: widget.establishmentName,
        establishmentLogoUrl: widget.establishmentLogoUrl,
        boissonId: '3',
        boissonName: 'Tembo 72cl',
        formule: '1+1=2',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 28)),
        isActive: true,
        isUnlimited: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PromotionModel(
        id: '3',
        establishmentId: widget.establishmentId,
        establishmentName: widget.establishmentName,
        establishmentLogoUrl: widget.establishmentLogoUrl,
        boissonId: '5',
        boissonName: 'Mützig 72cl',
        formule: '3+2=5',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        isActive: false,
        isUnlimited: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  Future<void> _toggleActive(PromotionModel promotion) async {
    // TODO: Call API to toggle active status
    setState(() {
      _promotions = _promotions.map((p) {
        if (p.id == promotion.id) {
          return p.copyWith(isActive: !p.isActive);
        }
        return p;
      }).toList();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            promotion.isActive ? 'Promotion désactivée' : 'Promotion activée',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: promotion.isActive ? AppColors.warning : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _deletePromotion(PromotionModel promotion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Supprimer la promotion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette promotion ? Cette action est irréversible.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Call API to delete promotion
      setState(() {
        _promotions.removeWhere((p) => p.id == promotion.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promotion supprimée',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  Future<void> _continuePromotion(PromotionModel promotion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Continuer la promotion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Voulez-vous continuer cette promotion sans limite de date ? Elle restera active indéfiniment jusqu\'à ce que vous la désactiviez manuellement.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Continuer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.yellowPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Call API to make promotion unlimited
      setState(() {
        _promotions = _promotions.map((p) {
          if (p.id == promotion.id) {
            return p.copyWith(
              isUnlimited: true,
              isActive: true,
            );
          }
          return p;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promotion continuée sans limite',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editPromotion(PromotionModel promotion) async {
    // Navigate to create promotion page with existing data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePromotionPage(
          establishmentId: widget.establishmentId,
          establishmentName: widget.establishmentName,
          enseigneUrl: widget.enseigneUrl,
          logoUrl: widget.establishmentLogoUrl,
          // TODO: Pass promotion data for editing
        ),
      ),
    );

    if (result == true) {
      _loadPromotions();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janv',
      'fév',
      'mars',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sept',
      'oct',
      'nov',
      'déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondaryLight,
      appBar: AppBar(
        title: Text(
          'Promotions',
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellowPrimary),
              ),
            )
          : _promotions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPromotions,
                  color: AppColors.yellowPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) {
                      return _PromotionListItem(
                        promotion: _promotions[index],
                        onToggleActive: () => _toggleActive(_promotions[index]),
                        onEdit: () => _editPromotion(_promotions[index]),
                        onDelete: () => _deletePromotion(_promotions[index]),
                        onContinue: () => _continuePromotion(_promotions[index]),
                        formatDate: _formatDate,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePromotionPage(
                establishmentId: widget.establishmentId,
                establishmentName: widget.establishmentName,
                enseigneUrl: widget.enseigneUrl,
                logoUrl: widget.establishmentLogoUrl,
              ),
            ),
          );
          if (result == true) {
            _loadPromotions();
          }
        },
        backgroundColor: AppColors.yellowPrimary,
        icon: const Icon(Icons.add, color: AppColors.textPrimaryLight),
        label: Text(
          'Nouvelle promotion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucune promotion',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Créez votre première promotion',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionListItem extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onContinue;
  final String Function(DateTime) formatDate;

  const _PromotionListItem({
    required this.promotion,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onContinue,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = !promotion.isUnlimited && promotion.endDate.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and status
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promotion image or placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(
                        color: AppColors.gray200,
                        width: 1,
                      ),
                    ),
                    child: promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            child: Image.network(
                              promotion.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.local_offer_rounded,
                                  color: AppColors.yellowPrimary,
                                  size: 32,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.local_offer_rounded,
                            color: AppColors.yellowPrimary,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Promotion details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
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
                                    : promotion.isActive && !isExpired
                                        ? AppColors.success.withOpacity(0.15)
                                        : AppColors.gray300.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall + 4),
                                border: Border.all(
                                  color: promotion.isUnlimited
                                      ? AppColors.info.withOpacity(0.4)
                                      : promotion.isActive && !isExpired
                                          ? AppColors.success.withOpacity(0.4)
                                          : AppColors.gray400.withOpacity(0.3),
                                  width: 1.5,
                                ),
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
                                          : promotion.isActive && !isExpired
                                              ? AppColors.success
                                              : AppColors.gray500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    promotion.isUnlimited
                                        ? 'Sans limite'
                                        : promotion.isActive && !isExpired
                                            ? 'Active'
                                            : isExpired
                                                ? 'Expirée'
                                                : 'Inactive',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: promotion.isUnlimited
                                          ? AppColors.info
                                          : promotion.isActive && !isExpired
                                              ? AppColors.success
                                              : AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Boisson name
                        Text(
                          promotion.boissonName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Formule
                        Text(
                          promotion.formule,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Dates
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppColors.textTertiaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              promotion.isUnlimited
                                  ? 'Sans date d\'expiration'
                                  : '${formatDate(promotion.startDate)} - ${formatDate(promotion.endDate)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondaryLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Toggle Active/Inactive
                  Expanded(
                    child: _ActionButton(
                      icon: promotion.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      label: promotion.isActive ? 'Désactiver' : 'Activer',
                      color: promotion.isActive ? AppColors.warning : AppColors.success,
                      onPressed: onToggleActive,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Edit
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Modifier',
                      color: AppColors.info,
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Continue (only if not unlimited)
                  if (!promotion.isUnlimited)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.update_rounded,
                        label: 'Continuer',
                        color: AppColors.yellowPrimary,
                        onPressed: onContinue,
                      ),
                    ),
                  if (!promotion.isUnlimited) const SizedBox(width: AppSpacing.xs),
                  // Delete
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
      ),
    );
  }
}

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
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
      ),
    );
  }
}



