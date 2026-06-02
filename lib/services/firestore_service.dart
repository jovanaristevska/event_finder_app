import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirestoreService {
  final CollectionReference _eventsRef =
  FirebaseFirestore.instance.collection('events');

  final CollectionReference _rsvpsRef =
  FirebaseFirestore.instance.collection('rsvps');

// Додади RSVP
  Future<void> addRsvp(String userId, String eventId) async {
    await _rsvpsRef.doc('${userId}_$eventId').set({
      'userId': userId,
      'eventId': eventId,
    });
  }

// Тргни RSVP
  Future<void> removeRsvp(String userId, String eventId) async {
    await _rsvpsRef.doc('${userId}_$eventId').delete();
  }

// Земи ги сите eventId што корисникот ги RSVP-ирал
  Future<Set<String>> getUserRsvps(String userId) async {
    final snapshot =
    await _rsvpsRef.where('userId', isEqualTo: userId).get();
    return snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['eventId'] as String)
        .toSet();
  }

// Изброј колку RSVP има еден настан (за trending)
  Future<int> countRsvps(String eventId) async {
    final snapshot =
    await _rsvpsRef.where('eventId', isEqualTo: eventId).get();
    return snapshot.docs.length;
  }

  // Зачувај нов настан
  Future<void> addEvent(EventModel event) async {
    await _eventsRef.add(event.toMap());
  }

  // Real-time stream на сите кориснички настани
  Stream<List<EventModel>> getEvents() {
    return _eventsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // Ажурирај постоечки настан
  Future<void> updateEvent(String id, EventModel event) async {
    await _eventsRef.doc(id).update(event.toMap());
  }

  // Избриши настан по ID
  Future<void> deleteEvent(String id) async {
    await _eventsRef.doc(id).delete();
  }}