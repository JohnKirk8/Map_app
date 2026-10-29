import 'dart:convert';

import 'package:latlong2/latlong.dart';

/// Represents a Destination / Spatial Point in the GeoAether Catalog.
class Course {
  final int id;
  final String code;
  final String title;
  final String description;
  final int credits; // Rating / Priority Level (1-5)
  final String instructor; // Category / Manager
  final double latitude;
  final double longitude;

  Course({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.credits,
    required this.instructor,
    required this.latitude,
    required this.longitude,
  });

  LatLng get location => LatLng(latitude, longitude);

  /// Factory constructor to parse JSON data into a location model
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      code:
          json['code'] ??
          'LOC-${100 + (json['id'] is int ? json['id'] as int : 1)}',
      title: json['title'] ?? 'Featured Location',
      description:
          json['body'] ??
          json['description'] ??
          'Geospatial landmark in Davao Region.',
      credits: json['credits'] is int ? json['credits'] as int : 4,
      instructor: json['instructor'] ?? json['category'] ?? 'Public Landmark',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 7.0707,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 125.6092,
    );
  }

  /// Converts a Course object into a JSON-encodable Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'credits': credits,
      'instructor': instructor,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Utility to create updated copies of a Location instance
  Course copyWith({
    int? id,
    String? code,
    String? title,
    String? description,
    int? credits,
    String? instructor,
    double? latitude,
    double? longitude,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      credits: credits ?? this.credits,
      instructor: instructor ?? this.instructor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Helper to decode a list of JSON records
  static List<Course> fromJsonList(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    return data
        .map((item) => Course.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
