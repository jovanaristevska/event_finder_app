# event_finder_app

# Event Finder

A social events app built with Flutter. Discover real events near you, create your own, RSVP to the ones you like, and see everything on an interactive map.

Event Finder combines **real events** pulled live from the Ticketmaster API with **user-created events** stored in Firebase Firestore, giving users a feed that is both rich and personal.

---

## Features

- **Authentication** — Email/password sign-up and login with Firebase Authentication, including name and surname on registration.
- **Event feed** — Browse real events from Ticketmaster alongside events created by users, each shown on a custom card with image, title, location, and date.
- **Trending** — A horizontal carousel of the most popular events, ranked by number of attendees.
- **Search** — Filter events instantly by title or location.
- **Create events** — Add your own event with a title, date & time picker, cover photo (camera or gallery), and a location picked directly on the map.
- **Edit & delete** — Full control over events you created, including updating the cover photo.
- **Map view** — See all events as markers on an OpenStreetMap map, plus a "my location" button that centers the map on your current GPS position.
- **RSVP** — Join events you're interested in. Your RSVPs are saved and persist across sessions.
- **Profile** — View your account, the events you created, and the events you're attending.

---

## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Provider
- **Authentication & database:** Firebase (Auth + Cloud Firestore)
- **Events API:** Ticketmaster Discovery API
- **Maps:** flutter_map with OpenStreetMap tiles
- **Location:** geolocator (GPS)
- **Media:** image_picker (camera & gallery)
- **Networking:** http

---

## Screens

| Screen | Description |
|--------|-------------|
| **Login / Register** | Email/password auth with a toggle between sign-in and sign-up. |
| **Home** | Search bar, trending carousel, and the full list of events. |
| **Event Details** | Full event info, RSVP button, plus edit/delete for your own events. |
| **Create Event** | Form with photo, date picker, and map-based location selection. |
| **Edit Event** | Pre-filled form to update an existing event. |
| **Map** | All events as markers, with current-location support. |
| **Profile** | User info, "My events", and "Future Events" (events attending). |

---

## Project Structure

```
lib/
├── models/
│   └── event_model.dart        # Event data model + JSON/Firestore mapping
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   └── event_provider.dart     # Events, trending, search, RSVP state
├── services/
│   ├── event_service.dart      # Ticketmaster API calls
│   ├── firestore_service.dart  # Firestore CRUD + RSVP
│   └── location_service.dart   # GPS location handling
├── screens/
│   ├── auth_gate.dart          # Routes between login and home
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── event_details_screen.dart
│   ├── create_event_screen.dart
│   ├── edit_event_screen.dart
│   ├── map_screen.dart
│   ├── profile_screen.dart
│   ├── notifications_screen.dart
│   └── main_navigation_screen.dart
├── firebase_options.dart       # Generated Firebase config
└── main.dart                   # App entry point
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- Android Studio with an emulator (or a physical device)
- A Firebase project
- A free Ticketmaster API key

### Setup

1. **Clone the repository**
   ```bash
   git clone [YOUR_REPO_URL]
   cd event-finder-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   Connect the app to your own Firebase project using the FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and the Android config. In the Firebase Console, enable **Email/Password** authentication and create a **Cloud Firestore** database (in test mode for development).

4. **Add your Ticketmaster API key**

   Get a free Consumer Key at [developer.ticketmaster.com](https://developer.ticketmaster.com), then paste it into `lib/services/event_service.dart`:
   ```dart
   static const String _apiKey = 'YOUR_CONSUMER_KEY';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## Permissions

The app requests the following Android permissions:

- `INTERNET` — for API calls and loading map tiles
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — for the "my location" feature on the map
- `CAMERA` — for taking event cover photos

---

## Notes

- **Event images:** Ticketmaster events use remote image URLs. User-created events store the photo locally on the device, so those images are visible on the device where they were created.
- **Data persistence:** User events and RSVPs are stored in Cloud Firestore and persist across sessions and devices.

---
