import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController locationController;
  late final TextEditingController dateController;
  File? _newImage;
  final ImagePicker _picker = ImagePicker();

  LatLng? _selectedLocation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Пополни ги полињата со постоечките вредности
    titleController = TextEditingController(text: widget.event.title);
    locationController = TextEditingController(text: widget.event.location);
    dateController = TextEditingController(text: widget.event.date);

    // Ако настанот веќе има координати, прикажи ги
    if (widget.event.latitude != null && widget.event.longitude != null) {
      _selectedLocation =
          LatLng(widget.event.latitude!, widget.event.longitude!);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final combined = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      dateController.text = _formatDateTime(combined);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
      });
    }
  }

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
                title: const Text("Камера"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Галерија"),
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

// Гради preview: нова слика > постоечка слика > placeholder
  Widget _buildImagePreview() {
    // 1. Ако корисникот избрал нова слика
    if (_newImage != null) {
      return Image.file(_newImage!,
          height: 180, width: double.infinity, fit: BoxFit.cover);
    }
    // 2. Постоечка слика на настанот
    final existing = widget.event.imageUrl;
    if (existing.isNotEmpty) {
      final isNetwork = existing.startsWith('http');
      return isNetwork
          ? Image.network(existing,
          height: 180, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _imgPlaceholder())
          : Image.file(File(existing),
          height: 180, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _imgPlaceholder());
    }
    // 3. Нема слика
    return _imgPlaceholder();
  }

  Widget _imgPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text("Add image", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.${dt.year} • $hour:$minute';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Создади ажуриран настан, задржувајќи ги непроменетите полиња
    final updated = EventModel(
      id: widget.event.id,
      title: titleController.text.trim(),
      location: locationController.text.trim(),
      date: dateController.text.trim(),
      imageUrl: _newImage?.path ?? widget.event.imageUrl, // сликата остануваат иста
      createdBy: widget.event.createdBy,
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      participants: widget.event.participants,
    );

    try {
      await Provider.of<EventProvider>(context, listen: false)
          .updateEvent(widget.event.id, updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error while saving.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Слика — тап за промена
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Event Title",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter location" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                readOnly: true,
                onTap: _pickDateTime,
                decoration: const InputDecoration(
                  labelText: "Date & Time",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please pick a date" : null,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Map location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _selectedLocation ??
                          const LatLng(41.9981, 21.4254),
                      initialZoom: 6,
                      onTap: (tapPosition, point) {
                        setState(() => _selectedLocation = point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.event_finder_app',
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveChanges,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save changes",
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}