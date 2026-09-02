class Poi {
  final String id;
  final String name;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String imagePath;
  final String imageUrl;
  final String address;
  final double rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const Poi({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imagePath = '',
    this.imageUrl = '',
    required this.address,
    required this.rating,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  String get displayImage => imageUrl.isNotEmpty ? imageUrl : imagePath;

  String get normalizedCategory => category.trim();

  factory Poi.fromJson(Map<String, dynamic> json, {String? id}) {
    return Poi(
      id: json['id']?.toString() ?? id ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      imagePath: json['imagePath']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      rating: _toDouble(json['rating']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'address': address,
      'rating': rating,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return null;
  }
}
