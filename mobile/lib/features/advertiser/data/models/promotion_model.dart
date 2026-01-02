/// Model for representing a promotion
class PromotionModel {
  final String id;
  final String establishmentId;
  final String establishmentName;
  final String? establishmentLogoUrl;
  final String boissonId;
  final String boissonName;
  final String? boissonImageUrl;
  final String formule;
  final String? imageUrl;
  final double? price; // Prix de la promotion
  final String? currency; // Devise: 'CDF' ou 'USD'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isUnlimited; // Promotion sans limite (continuée)
  final int interestedCount; // Nombre de personnes intéressées (comme "J'aime")
  final int viewCount; // Nombre de vues de la promotion
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PromotionModel({
    required this.id,
    required this.establishmentId,
    required this.establishmentName,
    this.establishmentLogoUrl,
    required this.boissonId,
    required this.boissonName,
    this.boissonImageUrl,
    required this.formule,
    this.imageUrl,
    this.price,
    this.currency,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.isUnlimited = false,
    this.interestedCount = 0,
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String? ?? '',
      establishmentId: json['establishmentId'] as String? ?? '',
      establishmentName: json['establishmentName'] as String? ?? '',
      establishmentLogoUrl: json['establishmentLogoUrl'] as String?,
      boissonId: json['boissonId'] as String? ?? '',
      boissonName: json['boissonName'] as String? ?? '',
      boissonImageUrl: json['boissonImageUrl'] as String?,
      formule: json['formule'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      price: json['price'] != null ? (json['price'] is num ? (json['price'] as num).toDouble() : double.tryParse(json['price'].toString())) : null,
      currency: json['currency'] as String?,
      startDate: json['startDate'] != null
          ? (json['startDate'] is DateTime
              ? json['startDate'] as DateTime
              : json['startDate'] is String
                  ? DateTime.parse(json['startDate'] as String)
                  : json['startDate'] is Map<String, dynamic>
                      ? ((json['startDate'] as Map<String, dynamic>).containsKey('_seconds')
                          ? DateTime.fromMillisecondsSinceEpoch(
                              ((json['startDate'] as Map<String, dynamic>)['_seconds'] as int) * 1000)
                          : DateTime.parse(json['startDate'].toString()))
                      : DateTime.now())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] is DateTime
              ? json['endDate'] as DateTime
              : json['endDate'] is String
                  ? DateTime.parse(json['endDate'] as String)
                  : json['endDate'] is Map<String, dynamic>
                      ? ((json['endDate'] as Map<String, dynamic>).containsKey('_seconds')
                          ? DateTime.fromMillisecondsSinceEpoch(
                              ((json['endDate'] as Map<String, dynamic>)['_seconds'] as int) * 1000)
                          : DateTime.parse(json['endDate'].toString()))
                      : DateTime.now())
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      isUnlimited: json['isUnlimited'] as bool? ?? false,
      interestedCount: json['interestedCount'] != null ? (json['interestedCount'] is int ? json['interestedCount'] as int : int.tryParse(json['interestedCount'].toString()) ?? 0) : 0,
      viewCount: json['viewCount'] != null ? (json['viewCount'] is int ? json['viewCount'] as int : int.tryParse(json['viewCount'].toString()) ?? 0) : 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : json['createdAt'] is String
                  ? DateTime.parse(json['createdAt'] as String)
                  : json['createdAt'] is Map<String, dynamic>
                      ? ((json['createdAt'] as Map<String, dynamic>).containsKey('_seconds')
                          ? DateTime.fromMillisecondsSinceEpoch(
                              ((json['createdAt'] as Map<String, dynamic>)['_seconds'] as int) * 1000)
                          : DateTime.parse(json['createdAt'].toString()))
                      : DateTime.now())
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : json['updatedAt'] is String
                  ? DateTime.parse(json['updatedAt'] as String)
                  : json['updatedAt'] is Map<String, dynamic>
                      ? ((json['updatedAt'] as Map<String, dynamic>).containsKey('_seconds')
                          ? DateTime.fromMillisecondsSinceEpoch(
                              ((json['updatedAt'] as Map<String, dynamic>)['_seconds'] as int) * 1000)
                          : DateTime.parse(json['updatedAt'].toString()))
                      : DateTime.now())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'establishmentLogoUrl': establishmentLogoUrl,
      'boissonId': boissonId,
      'boissonName': boissonName,
      'boissonImageUrl': boissonImageUrl,
      'formule': formule,
      'imageUrl': imageUrl,
      'price': price,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'isUnlimited': isUnlimited,
      'interestedCount': interestedCount,
      'viewCount': viewCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PromotionModel copyWith({
    String? id,
    String? establishmentId,
    String? establishmentName,
    String? establishmentLogoUrl,
    String? boissonId,
    String? boissonName,
    String? boissonImageUrl,
    String? formule,
    String? imageUrl,
    double? price,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isUnlimited,
    int? interestedCount,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      establishmentLogoUrl: establishmentLogoUrl ?? this.establishmentLogoUrl,
      boissonId: boissonId ?? this.boissonId,
      boissonName: boissonName ?? this.boissonName,
      boissonImageUrl: boissonImageUrl ?? this.boissonImageUrl,
      formule: formule ?? this.formule,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      interestedCount: interestedCount ?? this.interestedCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



