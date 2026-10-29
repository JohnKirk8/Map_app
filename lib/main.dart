import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/travel_pin.dart';
import 'course_list_screen.dart';

enum MapMode { classic, exploration }

class PlaceInfo {
  final String title;
  final String subtitle;
  final LatLng location;
  final bool isPin;
  final TravelPin? pin;
  final double? altitude;
  final String? placeType;

  PlaceInfo({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.isPin,
    this.pin,
    this.altitude,
    this.placeType,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully.");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(const GeoAetherApp());
}

class GeoAetherApp extends StatelessWidget {
  const GeoAetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoAether',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(
    text: "john.gaitano@jmc.edu.ph",
  );
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both email and password.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapScreen(userEmail: email)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              e.message ?? "Authentication failed. Please try again.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "An unexpected error occurred: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 12),
                  Text(
                    'GeoAether',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoginMode
                        ? 'Sign in to access map dashboard'
                        : 'Create a new GeoAether account',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isLoginMode
                                  ? 'Sign In to Dashboard'
                                  : 'Register Account',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? "Don't have an account? Register"
                          : 'Already registered? Sign In',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final String userEmail;
  const MapScreen({super.key, required this.userEmail});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  LatLng _currentLocation = const LatLng(7.0707, 125.6092);
  final List<LatLng> _gpsRoutePoints = [];
  final List<TravelPin> _pins = [];
  List<PlaceInfo> _searchResults = [];
  bool _isSearching = false;

  MapMode _currentMode = MapMode.classic;
  double _fogOpacity = 0.95;
  MapCamera? _activeCamera;

  PlaceInfo? _selectedTappedPlace;

  bool _isRulerActive = false;
  final List<LatLng> _rulerPoints = [];

  LatLng? _routeStart;
  String? _routeStartName;
  LatLng? _routeEnd;
  String? _routeEndName;
  List<LatLng> _navigationPolyline = [];
  double _routeDistanceKm = 0;
  double _routeDurationMin = 0;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _loadPinsFromJson();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPinsFromJson() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/locations.json',
      );
      final List<dynamic> data = jsonDecode(response);

      if (mounted) {
        setState(() {
          for (var item in data) {
            _pins.add(
              TravelPin(
                id: item['id'].toString(),
                title: item['title'] ?? 'JSON Pin',
                description: item['description'] ?? '',
                location: LatLng(
                  (item['latitude'] as num).toDouble(),
                  (item['longitude'] as num).toDouble(),
                ),
                mediaPath: item['mediaPath'],
              ),
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Loaded ${_pins.length} locations from JSON"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to load locations.json: $e");
    }
  }

  Future<void> _initLocationTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position currentPos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (mounted) {
      setState(() {
        _currentLocation = LatLng(currentPos.latitude, currentPos.longitude);
        _gpsRoutePoints.add(_currentLocation);
      });
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((Position position) {
      if (mounted) {
        LatLng newPoint = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newPoint;
          _gpsRoutePoints.add(newPoint);
        });
      }
    });
  }

  double _calculateDistanceMeters(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  double _calculateTotalRulerDistanceMeters() {
    if (_rulerPoints.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < _rulerPoints.length - 1; i++) {
      total += _calculateDistanceMeters(_rulerPoints[i], _rulerPoints[i + 1]);
    }
    return total;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180.0;
    double lon1 = start.longitude * math.pi / 180.0;
    double lat2 = end.latitude * math.pi / 180.0;
    double lon2 = end.longitude * math.pi / 180.0;

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360) % 360;
  }

  String _getCardinalDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'N';
    if (bearing >= 22.5 && bearing < 67.5) return 'NE';
    if (bearing >= 67.5 && bearing < 112.5) return 'E';
    if (bearing >= 112.5 && bearing < 157.5) return 'SE';
    if (bearing >= 157.5 && bearing < 202.5) return 'S';
    if (bearing >= 202.5 && bearing < 247.5) return 'SW';
    if (bearing >= 247.5 && bearing < 292.5) return 'W';
    return 'NW';
  }

  Future<double?> _fetchAltitude(LatLng location) async {
    try {
      final uri = Uri.parse(
        'https://api.open-elevation.com/api/v1/lookup?locations=${location.latitude},${location.longitude}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          return (data['results'][0]['elevation'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint("Elevation lookup error: $e");
    }
    return null;
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (_isRulerActive) {
      setState(() => _rulerPoints.add(point));
      return;
    }

    setState(() {
      _selectedTappedPlace = PlaceInfo(
        title: "Selected Location",
        subtitle:
            "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}",
        location: point,
        isPin: false,
      );
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&addressdetails=1',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'GeoAetherApp/1.0 (contact@geoaether.com)',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};

        String title =
            address['road'] ??
            address['suburb'] ??
            address['neighbourhood'] ??
            address['village'] ??
            address['town'] ??
            address['city'] ??
            address['county'] ??
            address['state'] ??
            data['display_name']?.toString().split(',').first ??
            "Selected Location";

        List<String> subParts = [];
        if (address['suburb'] != null && address['suburb'] != title)
          subParts.add(address['suburb']);
        if (address['village'] != null && address['village'] != title)
          subParts.add(address['village']);
        if (address['city'] != null && address['city'] != title)
          subParts.add(address['city']);
        if (address['state'] != null && address['state'] != title)
          subParts.add(address['state']);
        if (address['country'] != null) subParts.add(address['country']);

        String subtitle = subParts.take(3).join(', ');
        if (subtitle.isEmpty) subtitle = data['display_name'] ?? "Location";

        final place = PlaceInfo(
          title: title,
          subtitle: subtitle,
          location: point,
          isPin: false,
          placeType: data['type'],
        );

        if (mounted) {
          setState(() => _selectedTappedPlace = place);
          _showPlaceDetailsModal(place);
        }
        return;
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }

    if (mounted) {
      _showPlaceDetailsModal(_selectedTappedPlace!);
    }
  }

  void _onSearchQueryChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final lower = query.toLowerCase();
    List<PlaceInfo> results = [];

    for (var pin in _pins) {
      if (pin.title.toLowerCase().contains(lower) ||
          pin.description.toLowerCase().contains(lower)) {
        results.add(
          PlaceInfo(
            title: pin.title,
            subtitle: pin.description.isEmpty ? "Saved Pin" : pin.description,
            location: pin.location,
            isPin: true,
            pin: pin,
          ),
        );
      }
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=10',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'GeoAetherApp/1.0 (contact@geoaether.com)',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        for (var item in data) {
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);
          final displayName = item['display_name'] as String;
          final address = item['address'] as Map<String, dynamic>? ?? {};

          String mainName =
              address['road'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              address['village'] ??
              address['town'] ??
              address['city'] ??
              address['county'] ??
              address['state'] ??
              displayName.split(',')[0].trim();

          List<String> subParts = [];
          if (address['suburb'] != null && address['suburb'] != mainName)
            subParts.add(address['suburb']);
          if (address['city'] != null && address['city'] != mainName)
            subParts.add(address['city']);
          if (address['state'] != null && address['state'] != mainName)
            subParts.add(address['state']);
          if (address['country'] != null) subParts.add(address['country']);

          String subName = subParts.take(3).join(', ');
          if (subName.isEmpty) {
            final parts = displayName.split(',');
            subName = parts.skip(1).take(2).join(',').trim();
          }

          results.add(
            PlaceInfo(
              title: mainName,
              subtitle: subName.isEmpty ? "Place/Landmark" : subName,
              location: LatLng(lat, lon),
              isPin: false,
              placeType: item['type'] ?? item['class'],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _recenterOnUser() {
    _mapController.move(_currentLocation, 16.0);
  }

  Future<void> _calculateRouteOSRM() async {
    if (_routeStart == null || _routeEnd == null) return;

    setState(() => _isCalculatingRoute = true);

    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_routeStart!.longitude},${_routeStart!.latitude};'
          '${_routeEnd!.longitude},${_routeEnd!.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          List<LatLng> polylinePoints = coordinates.map((coord) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          double distanceMeters = (route['distance'] as num).toDouble();
          double durationSeconds = (route['duration'] as num).toDouble();

          if (mounted) {
            setState(() {
              _navigationPolyline = polylinePoints;
              _routeDistanceKm = distanceMeters / 1000.0;
              _routeDurationMin = durationSeconds / 60.0;
            });

            if (polylinePoints.isNotEmpty) {
              final bounds = LatLngBounds.fromPoints(polylinePoints);
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                ),
              );
            }
          }
        }
      } else {
        _setFallbackStraightLineRoute();
      }
    } catch (e) {
      debugPrint("Route calculation error: $e");
      _setFallbackStraightLineRoute();
    } finally {
      if (mounted) {
        setState(() => _isCalculatingRoute = false);
      }
    }
  }

  void _setFallbackStraightLineRoute() {
    if (_routeStart != null && _routeEnd != null) {
      setState(() {
        _navigationPolyline = [_routeStart!, _routeEnd!];
        _routeDistanceKm =
            _calculateDistanceMeters(_routeStart!, _routeEnd!) / 1000.0;
        _routeDurationMin = (_routeDistanceKm / 50.0) * 60.0;
      });
      final bounds = LatLngBounds.fromPoints([_routeStart!, _routeEnd!]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _routeStart = null;
      _routeStartName = null;
      _routeEnd = null;
      _routeEndName = null;
      _navigationPolyline = [];
      _routeDistanceKm = 0;
      _routeDurationMin = 0;
    });
  }

  void _openAddPinModal(
    LatLng position, {
    String? defaultTitle,
    String? defaultDesc,
  }) {
    final TextEditingController titleController = TextEditingController(
      text: defaultTitle ?? "",
    );
    final TextEditingController descController = TextEditingController(
      text: defaultDesc ?? "",
    );
    String? selectedFilePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPhoto(ImageSource source) async {
            final XFile? photo = await _imagePicker.pickImage(source: source);
            if (photo != null)
              setModalState(() => selectedFilePath = photo.path);
          }

          Future<void> pickVideo() async {
            final XFile? video = await _imagePicker.pickVideo(
              source: ImageSource.gallery,
            );
            if (video != null)
              setModalState(() => selectedFilePath = video.path);
          }

          Future<void> pickFile() async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result?.files.single.path != null) {
              setModalState(() => selectedFilePath = result!.files.single.path);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.push_pin, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      "Add Pin at Location",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Pin Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => pickPhoto(ImageSource.camera),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () => pickPhoto(ImageSource.gallery),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      onPressed: pickVideo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: pickFile,
                    ),
                  ],
                ),
                if (selectedFilePath != null && selectedFilePath!.isNotEmpty)
                  Text(
                    "Attached: ${selectedFilePath!.split('/').last}",
                    style: const TextStyle(color: Colors.green),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        setState(() {
                          _pins.add(
                            TravelPin(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              title: titleController.text,
                              description: descController.text,
                              location: position,
                              mediaPath: selectedFilePath,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Save Pin"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPlaceDetailsModal(PlaceInfo place) async {
    double distMeters = _calculateDistanceMeters(
      _currentLocation,
      place.location,
    );
    double bearingDeg = _calculateBearing(_currentLocation, place.location);
    String directionStr = _getCardinalDirection(bearingDeg);

    double? fetchedAltitude = place.altitude;
    if (fetchedAltitude == null) {
      fetchedAltitude = await _fetchAltitude(place.location);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        place.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (place.isPin && place.pin != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openPinEditModal(place.pin!);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deletePin(place.pin!);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ],
            ),
            const Divider(height: 24),

            Card(
              color: Colors.deepPurple.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.straighten, color: Colors.deepPurple),
                        const SizedBox(height: 4),
                        const Text(
                          "Distance",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          distMeters > 1000
                              ? "${(distMeters / 1000).toStringAsFixed(2)} km"
                              : "${distMeters.round()} m",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Transform.rotate(
                          angle: (bearingDeg * math.pi / 180.0),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.deepPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Direction",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          "${bearingDeg.round()}° $directionStr",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.terrain, color: Colors.deepPurple),
                        const SizedBox(height: 4),
                        const Text(
                          "Altitude",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          fetchedAltitude != null
                              ? "${fetchedAltitude.round()} m"
                              : "N/A",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            if (place.isPin && place.pin?.mediaPath != null) ...[
              const Text(
                "Attachment:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              _buildMediaPreview(place.pin!.mediaPath!),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.trip_origin, color: Colors.teal),
                    label: const Text("Route From"),
                    onPressed: () {
                      setState(() {
                        _routeStart = place.location;
                        _routeStartName = place.title;
                      });
                      Navigator.pop(ctx);

                      if (_routeEnd != null) {
                        _calculateRouteOSRM();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Origin set to '${place.title}'. Now select 'Route To'.",
                            ),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.directions_car),
                    label: const Text("Route To"),
                    onPressed: () {
                      setState(() {
                        if (_routeStart == null) {
                          _routeStart = _currentLocation;
                          _routeStartName = "My Location";
                        }
                        _routeEnd = place.location;
                        _routeEndName = place.title;
                      });
                      Navigator.pop(ctx);
                      _calculateRouteOSRM();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!place.isPin)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(
                    Icons.add_location_alt,
                    color: Colors.deepPurple,
                  ),
                  label: const Text("Save as Custom Permanent Pin"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openAddPinModal(
                      place.location,
                      defaultTitle: place.title,
                      defaultDesc: place.subtitle,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(path.split('/').last, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _openPinEditModal(TravelPin pin) {
    final TextEditingController titleController = TextEditingController(
      text: pin.title,
    );
    final TextEditingController descController = TextEditingController(
      text: pin.description,
    );
    String? selectedFilePath = pin.mediaPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPhoto(ImageSource source) async {
            final XFile? photo = await _imagePicker.pickImage(source: source);
            if (photo != null)
              setModalState(() => selectedFilePath = photo.path);
          }

          Future<void> pickVideo() async {
            final XFile? video = await _imagePicker.pickVideo(
              source: ImageSource.gallery,
            );
            if (video != null)
              setModalState(() => selectedFilePath = video.path);
          }

          Future<void> pickFile() async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result?.files.single.path != null) {
              setModalState(() => selectedFilePath = result!.files.single.path);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Travel Pin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => pickPhoto(ImageSource.camera),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () => pickPhoto(ImageSource.gallery),
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      onPressed: pickVideo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: pickFile,
                    ),
                  ],
                ),
                if (selectedFilePath != null && selectedFilePath!.isNotEmpty)
                  Text(
                    "Attached: ${selectedFilePath!.split('/').last}",
                    style: const TextStyle(color: Colors.green),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      setState(() {
                        pin.title = titleController.text;
                        pin.description = descController.text;
                        pin.mediaPath = selectedFilePath;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Update Pin"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _deletePin(TravelPin pin) {
    setState(() {
      _pins.removeWhere((p) => p.id == pin.id);
    });
  }

  IconData _getPlaceIcon(PlaceInfo place) {
    if (place.isPin) return Icons.push_pin;
    final type = place.placeType?.toLowerCase() ?? '';
    if (type.contains('city') ||
        type.contains('town') ||
        type.contains('administrative')) {
      return Icons.location_city;
    }
    if (type.contains('suburb') ||
        type.contains('village') ||
        type.contains('neighbourhood')) {
      return Icons.holiday_village;
    }
    if (type.contains('road') ||
        type.contains('highway') ||
        type.contains('street')) {
      return Icons.add_road;
    }
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    final double totalRulerDistM = _calculateTotalRulerDistanceMeters();

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('GeoAether Explorer'),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 36, color: Colors.deepPurple),
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('GeoAether Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(
                'Mode: ${_currentMode == MapMode.exploration ? "Exploration" : "Classic"}',
              ),
              subtitle: const Text('Tap to change mode'),
              onTap: () {
                setState(() {
                  _currentMode = _currentMode == MapMode.classic
                      ? MapMode.exploration
                      : MapMode.classic;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text('Loaded Pins (${_pins.length})'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.place_outlined,
                color: Colors.deepPurple,
              ),
              title: const Text('Featured Destinations'),
              subtitle: const Text('Davao Region Location Catalog'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseListScreen(
                      onLocationSelected: (targetLocation, targetTitle) {
                        _mapController.move(targetLocation, 16.0);
                        setState(() {
                          _selectedTappedPlace = PlaceInfo(
                            title: targetTitle,
                            subtitle:
                                "${targetLocation.latitude.toStringAsFixed(4)}, ${targetLocation.longitude.toStringAsFixed(4)}",
                            location: targetLocation,
                            isPin: false,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Moved camera to $targetTitle"),
                            backgroundColor: Colors.deepPurple,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) => _handleMapTap(point),
              onLongPress: (tapPosition, point) => _openAddPinModal(point),
              onMapReady: () {
                setState(() => _activeCamera = _mapController.camera);
              },
              onPositionChanged: (camera, hasGesture) {
                setState(() => _activeCamera = camera);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.login_page',
              ),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _gpsRoutePoints,
                    strokeWidth: 4.0,
                    color: Colors.blueAccent.withOpacity(0.6),
                  ),
                ],
              ),

              if (_navigationPolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navigationPolyline,
                      strokeWidth: 6.0,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),

              if (_rulerPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _rulerPoints,
                      strokeWidth: 4.0,
                      color: Colors.orange,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),

                  if (_selectedTappedPlace != null)
                    Marker(
                      point: _selectedTappedPlace!.location,
                      child: const Icon(
                        Icons.location_searching,
                        color: Colors.deepPurple,
                        size: 36,
                      ),
                    ),

                  ..._pins.map(
                    (pin) => Marker(
                      point: pin.location,
                      child: GestureDetector(
                        onTap: () => _showPlaceDetailsModal(
                          PlaceInfo(
                            title: pin.title,
                            subtitle: pin.description,
                            location: pin.location,
                            isPin: true,
                            pin: pin,
                          ),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 38,
                        ),
                      ),
                    ),
                  ),

                  if (_routeStart != null)
                    Marker(
                      point: _routeStart!,
                      child: const Icon(
                        Icons.trip_origin,
                        color: Colors.teal,
                        size: 32,
                      ),
                    ),

                  if (_routeEnd != null)
                    Marker(
                      point: _routeEnd!,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.deepPurple,
                        size: 34,
                      ),
                    ),

                  ..._rulerPoints.map(
                    (pt) => Marker(
                      point: pt,
                      child: const Icon(
                        Icons.circle,
                        color: Colors.orange,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_currentMode == MapMode.exploration && _activeCamera != null)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: FogOfWarPainter(
                  exploredPoints: [
                    ..._gpsRoutePoints,
                    ..._pins.map((p) => p.location),
                  ],
                  camera: _activeCamera!,
                  fogOpacity: _fogOpacity,
                ),
              ),
            ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: Builder(
                          builder: (context) => TextField(
                            controller: _searchController,
                            onChanged: _onSearchQueryChanged,
                            decoration: InputDecoration(
                              hintText:
                                  "Search city, barangay, road, region...",
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                              ),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchQueryChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'ruler_toggle_btn',
                      backgroundColor: _isRulerActive
                          ? Colors.orange
                          : Colors.white,
                      foregroundColor: _isRulerActive
                          ? Colors.white
                          : Colors.black87,
                      onPressed: () {
                        setState(() {
                          _isRulerActive = !_isRulerActive;
                          if (!_isRulerActive) _rulerPoints.clear();
                        });
                      },
                      child: const Icon(Icons.straighten),
                    ),
                  ],
                ),

                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          leading: Icon(
                            _getPlaceIcon(item),
                            color: item.isPin ? Colors.red : Colors.deepPurple,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _mapController.move(item.location, 15.0);
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _selectedTappedPlace = item;
                            });
                            _showPlaceDetailsModal(item);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          if (_isRulerActive)
            Positioned(
              top: 115,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.straighten, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            "Distance: " +
                                (totalRulerDistM >= 1000
                                    ? (totalRulerDistM / 1000).toStringAsFixed(
                                            2,
                                          ) +
                                          " km"
                                    : totalRulerDistM.round().toString() +
                                          " m") +
                                " (${_rulerPoints.length} points)",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setState(() => _rulerPoints.clear()),
                        child: const Text(
                          "Clear",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_navigationPolyline.isNotEmpty || _isCalculatingRoute)
            Positioned(
              bottom: 30,
              left: 16,
              right: 80,
              child: Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions,
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${_routeStartName ?? 'A'} ➔ ${_routeEndName ?? 'B'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _isCalculatingRoute
                                ? const Text(
                                    "Calculating route...",
                                    style: TextStyle(fontSize: 12),
                                  )
                                : Text(
                                    "${_routeDistanceKm.toStringAsFixed(1)} km (~${_routeDurationMin.round()} mins)",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _clearRoute,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 110,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'mode_btn',
                  onPressed: () {
                    setState(() {
                      _currentMode = _currentMode == MapMode.classic
                          ? MapMode.exploration
                          : MapMode.classic;
                    });
                  },
                  icon: Icon(
                    _currentMode == MapMode.exploration
                        ? Icons.explore
                        : Icons.map,
                  ),
                  label: Text(
                    _currentMode == MapMode.exploration
                        ? "Exploration"
                        : "Classic",
                  ),
                ),
                if (_currentMode == MapMode.exploration) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.opacity, size: 20),
                        SizedBox(
                          width: 110,
                          child: Slider(
                            value: _fogOpacity,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: "${(_fogOpacity * 100).round()}%",
                            onChanged: (val) {
                              setState(() => _fogOpacity = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'recenter_btn',
              onPressed: _recenterOnUser,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FogOfWarPainter extends CustomPainter {
  final List<LatLng> exploredPoints;
  final MapCamera camera;
  final double fogOpacity;

  FogOfWarPainter({
    required this.exploredPoints,
    required this.camera,
    required this.fogOpacity,
  });

  @override
  bool shouldRepaint(covariant FogOfWarPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(bounds, Paint());

    final fogPaint = Paint()
      ..color = Colors.black.withOpacity(fogOpacity.clamp(0.0, 1.0));
    canvas.drawRect(bounds, fogPaint);

    final eraserPaint = Paint()..blendMode = BlendMode.clear;
    final double baseRadiusAtZoom16 = 65.0;
    final double radiusPixels =
        baseRadiusAtZoom16 * math.pow(2, camera.zoom - 16.0);

    for (final point in exploredPoints) {
      final math.Point<double> pt = camera.latLngToScreenPoint(point);
      final Offset pixelOffset = Offset(pt.x, pt.y);

      if (pixelOffset.dx >= -radiusPixels &&
          pixelOffset.dx <= size.width + radiusPixels &&
          pixelOffset.dy >= -radiusPixels &&
          pixelOffset.dy <= size.height + radiusPixels) {
        canvas.drawCircle(pixelOffset, radiusPixels, eraserPaint);
      }
    }

    canvas.restore();
  }
}
