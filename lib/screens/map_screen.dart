import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _userLocation; // позиција на корисникот (ако ја земеме)
  bool _loadingLocation = false;

  // Зема GPS локација и ја центрира мапата
  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        setState(() => _userLocation = userLatLng);
        // Помести ја камерата на корисникот
        _mapController.move(userLatLng, 13);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events map"),
        centerTitle: true,
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventsWithCoords = provider.events
              .where((e) => e.latitude != null && e.longitude != null)
              .toList();

          if (eventsWithCoords.isEmpty) {
            return const Center(
              child: Text("Нема настани со локација за приказ"),
            );
          }

          final first = eventsWithCoords.first;

          // Маркери за настани
          final eventMarkers = eventsWithCoords.map((event) {
            return Marker(
              point: LatLng(event.latitude!, event.longitude!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showEventInfo(context, event),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          }).toList();

          // Маркер за корисникот (ако имаме локација)
          if (_userLocation != null) {
            eventMarkers.add(
              Marker(
                point: _userLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 36,
                ),
              ),
            );
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(first.latitude!, first.longitude!),
              initialZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.event_finder_app',
              ),
              MarkerLayer(markers: eventMarkers),
            ],
          );
        },
      ),
      // Копче за моја локација
      floatingActionButton: FloatingActionButton(
        onPressed: _loadingLocation ? null : _goToMyLocation,
        child: _loadingLocation
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.my_location),
      ),
    );
  }

  void _showEventInfo(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(event.location)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 6),
                  Text(event.date),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}