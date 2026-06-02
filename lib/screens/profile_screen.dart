import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import 'event_details_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final email = auth.user?.email ?? "Guest";
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final displayName = auth.user?.displayName ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, child) {
          // Настани што ги создал корисникот
          final myEvents = provider.events
              .where((e) => e.createdBy != null && e.createdBy == currentUserId)
              .toList();

          // Настани во кои корисникот учествува (RSVP)
          final joinedEvents = provider.events
              .where((e) => e.isJoined)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Аватар со прва буква од името (или email)
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : (email.isNotEmpty ? email[0].toUpperCase() : "?"),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Име (ако постои)
                if (displayName.isNotEmpty)
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 4),
                // Email
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                // Број на создадени настани
                Text(
                  "${myEvents.length} ${myEvents.length == 1 ? 'event' : 'events'} created",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Logout копче
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text("Log out"),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // === My events ===
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "My events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (myEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy,
                            size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "No events created",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myEvents.length,
                    itemBuilder: (context, index) {
                      return _myEventTile(context, myEvents[index]);
                    },
                  ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // === Future Events (RSVP) ===
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Future Events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (joinedEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.event_available,
                            size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "You're not attending any events yet",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: joinedEvents.length,
                    itemBuilder: (context, index) {
                      return _myEventTile(context, joinedEvents[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Мала картичка за настан во профилот
  Widget _myEventTile(BuildContext context, EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _tileImage(event.imageUrl),
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          event.date,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(event: event),
            ),
          );
        },
      ),
    );
  }

  // Мала слика (network, локален фајл, или placeholder)
  Widget _tileImage(String path) {
    const double size = 50;
    if (path.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.indigo.shade100,
        child: const Icon(Icons.event, color: Colors.indigo),
      );
    }
    final isNetwork = path.startsWith('http');
    return isNetwork
        ? Image.network(path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _imgFallback(size))
        : Image.file(File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _imgFallback(size));
  }

  Widget _imgFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.indigo.shade100,
      child: const Icon(Icons.event, color: Colors.indigo),
    );
  }
}