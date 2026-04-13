import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;
  final String herbBoxName = 'herbs_cache';

  Future<List<dynamic>> getHerbs() async {
    // 1. Updated for connectivity_plus 6.0.0+
    // It now returns a List because devices can have multiple connections (WiFi + Cellular)
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();

    // Open the Hive box
    var box = await Hive.openBox(herbBoxName);

    // 2. Check if we have any active internet connection
    bool isOnline = connectivityResult.any(
      (result) => result != ConnectivityResult.none,
    );

    if (isOnline) {
      // ONLINE: Fetch from Supabase
      try {
        // Note: I added the select join here so it matches the Herb model in your main.dart
        final data = await _supabase.from('herbs').select();

        await box.put(
          'all_herbs',
          data,
        ); // Save the list locally for offline use
        return data;
      } catch (e) {
        // If the network call fails for some reason, fall back to cache
        return box.get('all_herbs', defaultValue: []);
      }
    } else {
      // OFFLINE: Read from Local Cache
      return box.get('all_herbs', defaultValue: []);
    }
  }
}
