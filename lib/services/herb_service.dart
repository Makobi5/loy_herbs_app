import 'package:supabase_flutter/supabase_flutter.dart';
// 1. IMPORT YOUR MODEL (Make sure the path matches your project name)
import 'package:loy_herbs/data/models/herb_model.dart';

class HerbService {
  // 2. DEFINE THE SUPABASE CLIENT
  final _supabase = Supabase.instance.client;

  Future<List<Herb>> getHerbs() async {
    try {
      // Fetching herbs and joining with the diseases table
      final data = await _supabase
          .from('herbs')
          .select('*, herb_diseases(diseases(name))');

      // Convert the raw data list into a list of Herb objects
      final List<Herb> fetchedHerbs = (data as List)
          .map((e) => Herb.fromMap(e as Map<String, dynamic>))
          .toList();

      return fetchedHerbs;
    } catch (e) {
      print("Error in HerbService: $e");
      return [];
    }
  }
}
