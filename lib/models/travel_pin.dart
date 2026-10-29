import 'package:latlong2/latlong.dart';

class TravelPin {
  final String id;
  String title;
  String description;
  LatLng location;
  String? mediaPath;
  String? mediaType; // 'image', 'document', or null
  bool isPreset;

  TravelPin({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.mediaPath,
    this.mediaType,
    this.isPreset = false,
  });

  factory TravelPin.fromJson(Map<String, dynamic> json) {
    return TravelPin(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Pin',
      description: json['description'] ?? '',
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      mediaPath: json['mediaPath'],
      mediaType: json['mediaType'],
      isPreset: json['isPreset'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'mediaPath': mediaPath,
      'mediaType': mediaType,
      'isPreset': isPreset,
    };
  }
}