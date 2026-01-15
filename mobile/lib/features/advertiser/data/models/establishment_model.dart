import 'package:cloud_firestore/cloud_firestore.dart';

class EstablishmentModel {
  final String id;
  final String userId;
  final String type;
  final String name;
  final String logoUrl;
  final String enseigneUrl;
  final String? documentUrl;
  final LocationModel location;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EstablishmentModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.logoUrl,
    required this.enseigneUrl,
    this.documentUrl,
    required this.location,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) {
    return EstablishmentModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      enseigneUrl: json['enseigneUrl'] as String? ?? '',
      documentUrl: json['documentUrl'] as String?,
      location: LocationModel.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      isActive: json['isActive'] as bool? ?? true,
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
      'userId': userId,
      'type': type,
      'name': name,
      'logoUrl': logoUrl,
      'enseigneUrl': enseigneUrl,
      'documentUrl': documentUrl,
      'location': location.toJson(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper to get location string for display
  String get locationString {
    return '${location.quartier}, ${location.ville}';
  }
}

class LocationModel {
  final String ville;
  final String quartier;
  final String avenue;
  final String numero;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.ville,
    required this.quartier,
    required this.avenue,
    required this.numero,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      ville: json['ville'] as String? ?? '',
      quartier: json['quartier'] as String? ?? '',
      avenue: json['avenue'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
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
}

