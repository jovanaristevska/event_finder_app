import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class EventProvider with ChangeNotifier {
  final EventService _service = EventService();
  final FirestoreService _firestore = FirestoreService();
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<EventModel> _apiEvents = [];      // од Ticketmaster
  List<EventModel> _userEvents = [];     // од Firestore
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _firestoreSub;

  // Спој ги: кориснички настани прво, потоа API
  List<EventModel> get events => [..._userEvents, ..._apiEvents];

  // Trending: топ 5 настани по број на учесници
  List<EventModel> get trendingEvents {
    // Само настани со барем 1 учесник
    final withParticipants =
    events.where((e) => e.participants > 0).toList();
    withParticipants.sort((a, b) => b.participants.compareTo(a.participants));
    return withParticipants.take(5).toList();
  }

// Филтрирани настани според пребарувањето
  List<EventModel> get filteredEvents {
    if (_searchQuery.isEmpty) return events;
    final q = _searchQuery.toLowerCase();
    return events.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  EventProvider() {
    _listenToUserEvents();
  }

  // Слушај real-time на Firestore настани
  void _listenToUserEvents() {
    _firestoreSub = _firestore.getEvents().listen((events) async {
      _userEvents = events;
      await _applyRsvps();
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _apiEvents = await _service.fetchEvents();
      // По вчитување, означи ги RSVP-ираните
      await _applyRsvps();
    } catch (e) {
      _error = 'Не може да се вчитаат настаните. Обиди се повторно.';
    }

    _isLoading = false;
    notifyListeners();
  }

// Означи кои настани се RSVP-ирани од корисникот
  Future<void> _applyRsvps() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final rsvpedIds = await _firestore.getUserRsvps(userId);

    // Означи ги во двете листи
    for (final event in [..._apiEvents, ..._userEvents]) {
      if (rsvpedIds.contains(event.id)) {
        if (!event.isJoined) {
          event.isJoined = true;
          event.participants++; // прикажи дека има барем 1 (корисникот)
        }
      }
    }
  }

  // Зачувај нов кориснички настан во Firestore
  // (stream-от автоматски ќе го додаде во листата)
  Future<void> addEvent(EventModel event) async {
    await _firestore.addEvent(event);
  }

  // Ажурирај кориснички настан
  Future<void> updateEvent(String id, EventModel event) async {
    await _firestore.updateEvent(id, event);
  }

  // Избриши кориснички настан
  Future<void> deleteEvent(String id) async {
    await _firestore.deleteEvent(id);
  }

  Future<void> toggleJoin(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final event = events.firstWhere((event) => event.id == id);
    event.isJoined = !event.isJoined;

    if (event.isJoined) {
      event.participants++;
      await _firestore.addRsvp(userId, id);
    } else {
      event.participants--;
      await _firestore.removeRsvp(userId, id);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }
}