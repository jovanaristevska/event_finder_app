import 'package:geolocator/geolocator.dart';

class LocationService {
  // Зема тековна локација, бара дозвола ако треба
  Future<Position?> getCurrentLocation() async {
    // 1. Дали е вклучена локацијата на уредот?
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Локацијата е исклучена на уредот.';
    }

    // 2. Провери/побарај дозвола
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Дозволата за локација е одбиена.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Дозволата за локација е трајно одбиена. Промени во поставки.';
    }

    // 3. Земи ја позицијата
    return await Geolocator.getCurrentPosition();
  }
}