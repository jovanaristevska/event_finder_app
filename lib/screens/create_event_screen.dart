import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final dateController = TextEditingController();

  bool _saving = false;
  DateTime? _selectedDateTime;
  LatLng? _selectedLocation;
  File? _selectedImage; // избраната слика (локален фајл)
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;

    final newEvent = EventModel(
      id: '',
      title: titleController.text.trim(),
      location: locationController.text.trim(),
      date: dateController.text.trim(),
      imageUrl: _selectedImage?.path ?? '',
      createdBy: userId,
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
    );

    try {
      await Provider.of<EventProvider>(context, listen: false)
          .addEvent(newEvent);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Грешка при зачувување.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDateTime() async {
    // 1. Избери датум од календар
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // не дозволувај датум во минатото
      lastDate: DateTime(2030),
    );

    if (date == null) return; // корисникот откажа

    if (!mounted) return;

    // 2. Избери време од часовник
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    // 3. Спој датум + време
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _selectedDateTime = combined;
      // Прикажи го форматирано во полето
      dateController.text = _formatDateTime(combined);
    });
  }

// Форматирање за приказ: "15.06.2026 • 18:30"
  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.${dt.year} • $hour:$minute';
  }

  // Зема слика од камера или галерија
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1000, // намали резолуција за да не е преголема
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

// Прикажува избор: камера или галерија
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Preview на избраната слика или копче за додавање
              _selectedImage != null
                  ? GestureDetector(
                onTap: _showImageSourceDialog, // тап на сликата = промени ја
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add photo"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Event Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter title";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter location";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                readOnly: true, // не може да се пишува рачно
                onTap: _pickDateTime, // тап отвора календар
                decoration: const InputDecoration(
                  labelText: "Date & Time",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please pick a date";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

// Наслов за делот со мапа
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose location on map",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),

// Мапа за избор на локација
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(41.9981, 21.4254), // Скопје како почеток
                      initialZoom: 6,
                      onTap: (tapPosition, point) {
                        // Кога корисникот тапнува, постави маркер таму
                        setState(() {
                          _selectedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.event_finder_app',
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

// Покажи ги избраните координати (или потсетник)
              if (_selectedLocation != null)
                Text(
                  "${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saving ? null : saveEvent,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Create Event",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}