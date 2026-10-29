import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'models/course_model.dart';
import 'services/course_service.dart';

class CourseListScreen extends StatefulWidget {
  final Function(LatLng location, String title)? onLocationSelected;

  const CourseListScreen({super.key, this.onLocationSelected});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseService _courseService = CourseService();
  late Future<List<Course>> _coursesFuture;
  List<Course> _currentCourses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshCourses();
  }

  void _refreshCourses() {
    setState(() {
      _coursesFuture = _courseService.getCourses();
    });
  }

  // UI Modal: Add / Edit Destination
  void _showCourseFormModal({Course? existingCourse}) {
    final isEditing = existingCourse != null;
    final codeController = TextEditingController(
      text: existingCourse?.code ?? 'LOC-201',
    );
    final titleController = TextEditingController(
      text: existingCourse?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingCourse?.description ?? '',
    );
    final ratingController = TextEditingController(
      text: (existingCourse?.credits ?? 5).toString(),
    );
    final categoryController = TextEditingController(
      text: existingCourse?.instructor ?? 'Urban Point',
    );
    final latController = TextEditingController(
      text: (existingCourse?.latitude ?? 7.0707).toString(),
    );
    final lngController = TextEditingController(
      text: (existingCourse?.longitude ?? 125.6092).toString(),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            isEditing
                                ? 'Edit Location Details'
                                : 'Add New Destination',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Location Code',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter code' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Landmark Title',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description & Highlights',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter description'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            prefixIcon: Icon(Icons.navigation),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || double.tryParse(val) == null
                              ? 'Valid number'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            prefixIcon: Icon(Icons.explore),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || double.tryParse(val) == null
                              ? 'Valid number'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ratingController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Rating (1-5)',
                            prefixIcon: Icon(Icons.star),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || int.tryParse(val) == null
                              ? 'Valid number'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);

                          try {
                            if (isEditing) {
                              final updated = existingCourse.copyWith(
                                code: codeController.text.trim(),
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                credits: int.parse(
                                  ratingController.text.trim(),
                                ),
                                instructor: categoryController.text.trim(),
                                latitude: double.parse(
                                  latController.text.trim(),
                                ),
                                longitude: double.parse(
                                  lngController.text.trim(),
                                ),
                              );

                              await _courseService.updateCourse(updated);
                              _showSnackBar('Location updated successfully!');
                            } else {
                              final newCourse = Course(
                                id: 0,
                                code: codeController.text.trim(),
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                credits: int.parse(
                                  ratingController.text.trim(),
                                ),
                                instructor: categoryController.text.trim(),
                                latitude: double.parse(
                                  latController.text.trim(),
                                ),
                                longitude: double.parse(
                                  lngController.text.trim(),
                                ),
                              );

                              await _courseService.createCourse(newCourse);
                              _showSnackBar('New location added to catalog!');
                            }
                            _refreshCourses();
                          } catch (e) {
                            _showSnackBar(
                              'Error updating record: $e',
                              isError: true,
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: Text(
                        isEditing ? 'Save Changes' : 'Register Location',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Confirm Removal
  void _confirmDeleteCourse(Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Destination'),
        content: Text(
          'Are you sure you want to remove "${course.title}" from the list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await _courseService.deleteCourse(course.id);
                _showSnackBar('Location removed from catalog.');
                _refreshCourses();
              } catch (e) {
                _showSnackBar('Failed to remove location: $e', isError: true);
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('park')) return Icons.park;
    if (lower.contains('resort') || lower.contains('mountain'))
      return Icons.terrain;
    if (lower.contains('transport') || lower.contains('airport'))
      return Icons.flight;
    if (lower.contains('terminal')) return Icons.directions_boat;
    if (lower.contains('civic') || lower.contains('hall'))
      return Icons.location_city;
    if (lower.contains('lookout') || lower.contains('scenic'))
      return Icons.remove_red_eye;
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Davao Destinations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCourses,
            tooltip: 'Sync Catalog Data',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseFormModal(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Location'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Course>>(
            future: _coursesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading Featured Destinations...'),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Synchronization Error',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshCourses,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Sync'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No destinations found in catalog.'),
                );
              }

              _currentCourses = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async => _refreshCourses(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _currentCourses.length,
                  itemBuilder: (context, index) {
                    final item = _currentCourses[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (widget.onLocationSelected != null) {
                            widget.onLocationSelected!(
                              item.location,
                              item.title,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(item.instructor),
                                        color: Colors.deepPurple,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          item.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 22,
                                        ),
                                        onPressed: () => _showCourseFormModal(
                                          existingCourse: item,
                                        ),
                                        tooltip: 'Edit Location',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _confirmDeleteCourse(item),
                                        tooltip: 'Remove Location',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.my_location,
                                    size: 14,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "•  Tap card to view on map",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.category,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.instructor,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: List.generate(
                                      item.credits,
                                      (i) => const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
