import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for location information
class PromotionLocation {
  final String? ville;
  final String? quartier;
  final String? avenue;
  final String? numero;
  final double? latitude;
  final double? longitude;

  PromotionLocation({
    this.ville,
    this.quartier,
    this.avenue,
    this.numero,
    this.latitude,
    this.longitude,
  });

  factory PromotionLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PromotionLocation();
    return PromotionLocation(
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      avenue: json['avenue'] as String?,
      numero: json['numero'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ville': ville,
      'quartier': quartier,
      'avenue': avenue,
      'numero': numero,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Get formatted address string
  String get formattedAddress {
    final parts = <String>[];
    if (numero != null && numero!.isNotEmpty) parts.add(numero!);
    if (avenue != null && avenue!.isNotEmpty) parts.add(avenue!);
    if (quartier != null && quartier!.isNotEmpty) parts.add(quartier!);
    if (ville != null && ville!.isNotEmpty) parts.add(ville!);
    return parts.join(', ');
  }
}

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
  final PromotionLocation? location; // Informations de localisation de l'établissement
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
    this.location,
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
              : json['startDate'] is Timestamp
                  ? (json['startDate'] as Timestamp).toDate()
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
              : json['endDate'] is Timestamp
                  ? (json['endDate'] as Timestamp).toDate()
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
      location: json['location'] != null ? PromotionLocation.fromJson(json['location'] as Map<String, dynamic>?) : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : json['createdAt'] is Timestamp
                  ? (json['createdAt'] as Timestamp).toDate()
                  : json['createdAt'] is String
                      ? DateTime.parse(json['createdAt'] as String)
                      : json['createdAt'] is Map<String, dynamic>
                          ? ((json['createdAt'] as Map<String, dynamic>).containsKey('_seconds')
                              ? DateTime.fromMillisecondsSinceEpoch(
                                  ((json['createdAt'] as Map<String, dynamic>)['_seconds'] as int) * 1000)
                              : DateTime.parse(json['createdAt'].toString()))
                          : null)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : json['updatedAt'] is Timestamp
                  ? (json['updatedAt'] as Timestamp).toDate()
                  : json['updatedAt'] is String
                      ? DateTime.parse(json['updatedAt'] as String)
                      : json['updatedAt'] is Map<String, dynamic>
                          ? ((json['updatedAt'] as Map<String, dynamic>).containsKey('_seconds')
                              ? DateTime.fromMillisecondsSinceEpoch(
                                  ((json['updatedAt'] as Map<String, dynamic>)['_seconds'] as int) * 1000)
                              : DateTime.parse(json['updatedAt'].toString()))
                          : null)
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
      'location': location?.toJson(),
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
    PromotionLocation? location,
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
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



