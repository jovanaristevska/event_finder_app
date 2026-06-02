class EventModel {
  final String id;
  final String title;
  final String location;
  final String date;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final String? createdBy; // user ID на креаторот (null за Ticketmaster)
  bool isJoined;
  int participants;

  EventModel({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.createdBy,
    this.isJoined = false,
    this.participants = 0,
  });

  // === Ticketmaster (исто како досега) ===
  factory EventModel.fromTicketmaster(Map<String, dynamic> json) {
    final dates = json['dates']?['start'];
    final localDate = dates?['localDate'] ?? '';
    final localTime = dates?['localTime'] ?? '';
    final dateString = localTime.isNotEmpty
        ? '$localDate • ${localTime.substring(0, 5)}'
        : localDate;

    String venueLocation = 'Unknown';
    double? lat;
    double? lng;

    final venues = json['_embedded']?['venues'];
    if (venues != null && venues.isNotEmpty) {
      final venue = venues[0];
      final venueName = venue['name'] ?? '';
      final city = venue['city']?['name'] ?? '';
      venueLocation = [venueName, city]
          .where((s) => s.toString().isNotEmpty)
          .join(', ');

      final loc = venue['location'];
      if (loc != null) {
        lat = double.tryParse(loc['latitude']?.toString() ?? '');
        lng = double.tryParse(loc['longitude']?.toString() ?? '');
      }
    }

    String image = '';
    final images = json['images'];
    if (images != null && images.isNotEmpty) {
      image = images[0]['url'] ?? '';
    }

    return EventModel(
      id: json['id'] ?? DateTime.now().toString(),
      title: json['name'] ?? 'Untitled Event',
      location: venueLocation,
      date: dateString,
      imageUrl: image,
      latitude: lat,
      longitude: lng,
    );
  }

  // === Firestore: пишување (EventModel → Map) ===
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'date': date,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': createdBy,
      'participants': participants,
    };
  }

  // === Firestore: читање (Map → EventModel) ===
  factory EventModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return EventModel(
      id: docId,
      title: data['title'] ?? 'Untitled Event',
      location: data['location'] ?? 'Unknown',
      date: data['date'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdBy: data['createdBy'],
      participants: data['participants'] ?? 0,
    );
  }
}