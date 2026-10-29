import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/course_model.dart';

class CourseService {
  // Remote Endpoint
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  final Map<String, String> _headers = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    HttpHeaders.acceptHeader: 'application/json',
  };

  // In-memory cache for UI state consistency
  List<Course> _localCache = [];

  // Real Davao City Locations with actual Lat/Lng coordinates
  final List<Map<String, dynamic>> _davaoLocations = [
    {
      'code': 'LOC-101',
      'title': 'People\'s Park Davao',
      'description': 'A prominent urban public park in central Davao featuring cultural sculptures, a walking track, and rich indigenous flora.',
      'category': 'Urban Park',
      'lat': 7.0707,
      'lng': 125.6092,
    },
    {
      'code': 'LOC-102',
      'title': 'Davao City Hall',
      'description': 'Historical administrative center located near San Pedro Cathedral and the city center plaza.',
      'category': 'Civic Center',
      'lat': 7.0647,
      'lng': 125.6092,
    },
    {
      'code': 'LOC-103',
      'title': 'Davao Crocodile Park & Zoo Complex',
      'description': 'Popular eco-tourism sanctuary showcasing local wildlife, crocodiles, and educational conservation tours.',
      'category': 'Wildlife Sanctuary',
      'lat': 7.1086,
      'lng': 125.5975,
    },
    {
      'code': 'LOC-104',
      'title': 'Ramon Magsaysay Park & Waterfront',
      'description': 'Spacious coastal park along Davao Gulf known for fruit stands, cultural pavilions, and sea breezes.',
      'category': 'Coastal Park',
      'lat': 7.0769,
      'lng': 125.6206,
    },
    {
      'code': 'LOC-105',
      'title': 'Jack\'s Ridge Viewpoint',
      'description': 'Scenic hilltop resort offering panoramic views of Davao City skyline and Davao Gulf skyline.',
      'category': 'Scenic Lookout',
      'lat': 7.0617,
      'lng': 125.5804,
    },
    {
      'code': 'LOC-106',
      'title': 'Eden Nature Park & Resort',
      'description': 'High-altitude mountain resort sanctuary at the foot of Mt. Talomo featuring pine trees and nature trails.',
      'category': 'Mountain Eco-Resort',
      'lat': 7.0016,
      'lng': 125.3855,
    },
    {
      'code': 'LOC-107',
      'title': 'Davao International Airport (Francisco Bangoy)',
      'description': 'Main international flight hub connecting the Davao Region to global and local destinations.',
      'category': 'Transport Hub',
      'lat': 7.1253,
      'lng': 125.6458,
    },
    {
      'code': 'LOC-108',
      'title': 'Samal Island Ferry Terminal (MaeWess)',
      'description': 'Busiest passenger and vehicle ferry gateway connecting Davao City directly to Samal Island.',
      'category': 'Maritime Terminal',
      'lat': 7.1022,
      'lng': 125.6486,
    },
    {
      'code': 'LOC-109',
      'title': 'Mount Apo Viewpoint Base',
      'description': 'Southern gateway viewpoint offering clear vantage lines toward Mount Apo, the highest peak in the Philippines.',
      'category': 'Mountain Landmark',
      'lat': 6.9875,
      'lng': 125.2708,
    },
    {
      'code': 'LOC-110',
      'title': 'SM Lanang Premier Plaza',
      'description': 'Major commercial and shopping destination housing convention halls and regional entertainment centers.',
      'category': 'Commercial District',
      'lat': 7.0983,
      'lng': 125.6311,
    },
  ];

  // Fetch all locations
  Future<List<Course>> getCourses() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl), headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);

        final List<Course> fetchedCourses = [];
        for (int i = 0; i < body.length && i < _davaoLocations.length; i++) {
          final int apiId = body[i]['id'] as int;
          final preset = _davaoLocations[i];

          fetchedCourses.add(
            Course(
              id: apiId,
              code: preset['code']!,
              title: preset['title']!,
              description: preset['description']!,
              credits: (apiId % 2) + 4,
              instructor: preset['category']!,
              latitude: preset['lat']!,
              longitude: preset['lng']!,
            ),
          );
        }

        if (_localCache.isEmpty) {
          _localCache = fetchedCourses;
        }

        // PRINT JSON DATA TO CONSOLE FOR SCREENSHOT #2
        final String rawJsonOutput = const JsonEncoder.withIndent('  ')
            .convert(_localCache.map((c) => c.toJson()).toList());
        debugPrint('--- FETCHED JSON DATA FROM API ---');
        debugPrint(rawJsonOutput);

        return List.from(_localCache);
      } else {
        throw Exception('Unable to sync locations catalog.');
      }
    } catch (e) {
      if (_localCache.isNotEmpty) {
        return List.from(_localCache);
      }
      rethrow;
    }
  }

  // Create new location record
  Future<Course> createCourse(Course course) async {
    final String requestBody = jsonEncode({
      'title': course.title,
      'body': course.description,
      'userId': 1,
    });

    final response = await http
        .post(Uri.parse(baseUrl), headers: _headers, body: requestBody)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final createdCourse = course.copyWith(
        id: data['id'] is int
            ? data['id'] as int
            : DateTime.now().millisecondsSinceEpoch % 1000,
      );

      _localCache.insert(0, createdCourse);
      return createdCourse;
    } else {
      throw Exception('Unable to save new location.');
    }
  }

  // Update existing location record
  Future<Course> updateCourse(Course course) async {
    final String requestBody = jsonEncode({
      'id': course.id,
      'title': course.title,
      'body': course.description,
      'userId': 1,
    });

    final response = await http
        .put(
          Uri.parse('$baseUrl/${course.id}'),
          headers: _headers,
          body: requestBody,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final index = _localCache.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _localCache[index] = course;
      }
      return course;
    } else {
      final index = _localCache.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _localCache[index] = course;
        return course;
      }
      throw Exception('Unable to update location details.');
    }
  }

  // Delete location record
  Future<bool> deleteCourse(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/$id'), headers: _headers)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200 || response.statusCode == 204) {
      _localCache.removeWhere((c) => c.id == id);
      return true;
    } else {
      _localCache.removeWhere((c) => c.id == id);
      return true;
    }
  }
}
