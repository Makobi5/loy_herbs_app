class Herb {
  final String id;
  final String name;
  final String? scientificName;
  final String description;
  final String preparation;
  final String? imageUrl;
  final List<String> diseases; // We'll join these from the DB

  Herb({
    required this.id,
    required this.name,
    this.scientificName,
    required this.description,
    required this.preparation,
    this.imageUrl,
    required this.diseases,
  });

  // Convert Supabase Map to Herb Object
  factory Herb.fromMap(Map<String, dynamic> map) {
    return Herb(
      id: map['id'],
      name: map['name'],
      scientificName: map['scientific_name'],
      description: map['description'],
      preparation: map['preparation_method'],
      imageUrl: map['image_url'],
      // This assumes we fetch joined data
      diseases: List<String>.from(
        map['herb_diseases']?.map((x) => x['diseases']['name']) ?? [],
      ),
    );
  }
}
