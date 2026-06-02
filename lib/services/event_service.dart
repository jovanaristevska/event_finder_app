import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class EventService {
  // Замени го со твојот Consumer Key од Ticketmaster
  static const String _apiKey = 'eHy0kQgymC4qK2j1s3IzYcnA3E7Cq10n';
  static const String _baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  // Повлекува настани од Ticketmaster
  Future<List<EventModel>> fetchEvents({String countryCode = 'DE'}) async {
    final url = Uri.parse(
      '$_baseUrl/events.json?apikey=$_apiKey&countryCode=$countryCode&size=50',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Ако нема настани, _embedded го нема во одговорот
      final embedded = data['_embedded'];
      if (embedded == null) return [];

      final List eventsJson = embedded['events'] ?? [];
      return eventsJson
          .map((json) => EventModel.fromTicketmaster(json))
          .toList();
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }
}