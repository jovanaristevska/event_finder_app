import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Finder"),
        centerTitle: true,
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadEvents(),
                    child: const Text("Обиди се повторно"),
                  ),
                ],
              ),
            );
          }

          final isSearching = provider.searchQuery.isNotEmpty;
          final eventsToShow = provider.filteredEvents;

          return RefreshIndicator(
            onRefresh: () => provider.loadEvents(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: "Пребарај настани...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: isSearching
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Trending секција — само кога НЕ се пребарува
                if (!isSearching && provider.trendingEvents.isNotEmpty) ...[
                  const Text(
                    "🔥 Trending",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.trendingEvents.length,
                      itemBuilder: (context, index) {
                        return _trendingCard(
                            context, provider.trendingEvents[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Сите настани",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Резултати од пребарување (наслов)
                if (isSearching) ...[
                  Text(
                    "${eventsToShow.length} резултати",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Главна листа
                if (eventsToShow.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text("Нема настани")),
                  )
                else
                  ...eventsToShow.map((event) => eventCard(context, event)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Мала trending картичка (хоризонтална)
  Widget _trendingCard(BuildContext context, EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: event.imageUrl.isNotEmpty
                      ? _buildEventImage(event.imageUrl, height: 90)
                      : _placeholderImage(height: 90),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 14, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          "${event.participants}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget eventCard(BuildContext context, EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: event.imageUrl.isNotEmpty
                  ? _buildEventImage(event.imageUrl)
                  : _placeholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.location)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 4),
                      Text(event.date),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(String path, {double height = 180}) {
    final isNetwork = path.startsWith('http');
    return isNetwork
        ? Image.network(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _placeholderImage(height: height),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    )
        : Image.file(
      File(path),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _placeholderImage(height: height),
    );
  }

  Widget _placeholderImage({double height = 180}) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.indigo.shade100,
      child: Icon(Icons.event, size: height / 3, color: Colors.indigo),
    );
  }
}