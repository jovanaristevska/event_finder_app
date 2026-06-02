import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_event_screen.dart';
import 'dart:io';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });
  Widget _detailPlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.indigo.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(Icons.event, size: 80, color: Colors.indigo),
      ),
    );
  }

  Widget _detailImage(String path) {
    final isNetwork = path.startsWith('http');
    return isNetwork
        ? Image.network(
      path,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _detailPlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 220,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    )
        : Image.file(
      File(path),
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _detailPlaceholder(),
    );
  }

  void _confirmDelete(BuildContext context, EventProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Избриши настан"),
          content: Text("Дали сакаш да го избришеш \"${event.title}\"?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Откажи"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // затвори дијалог
                await provider.deleteEvent(event.id);
                if (context.mounted) {
                  Navigator.pop(context); // врати се на Home
                }
              },
              child: const Text(
                "Избриши",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(event.title),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share),
              ),
              if (event.createdBy != null &&
                  event.createdBy == FirebaseAuth.instance.currentUser?.uid) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditEventScreen(event: event),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, provider),
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: event.imageUrl.isNotEmpty
                            ? _detailImage(event.imageUrl)
                            : _detailPlaceholder(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 6),
                          Expanded(child: Text(event.location)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 6),
                          Text(event.date),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 6),
                          Text("${event.participants} participants"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "About Event",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Join this amazing event and meet new people, learn new things and have fun.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              // Копчето секогаш на дното, надвор од скролот
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.toggleJoin(event.id);
                    },
                    child: Text(
                      event.isJoined ? "Cancel RSVP" : "Join Event",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}