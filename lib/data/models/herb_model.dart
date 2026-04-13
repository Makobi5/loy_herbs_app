class Herb {
  final String id;
  final String name;
  final String? scientificName;
  final String description;
  final String preparation;
  final String? imageUrl;
  final List<String> diseases;

  Herb({
    required this.id,
    required this.name,
    this.scientificName,
    required this.description,
    required this.preparation,
    this.imageUrl,
    required this.diseases,
  });

  // PLACE IT HERE INSIDE THE CLASS
  factory Herb.fromMap(Map<String, dynamic> map) {
    return Herb(
      id: map['id'],
      name: map['name'] ?? 'Unknown Herb',
      scientificName: map['scientific_name'] ?? 'N/A',
      description: map['description'] ?? 'No description provided.',
      preparation: map['preparation_method'] ?? 'No instructions.',
      imageUrl: map['image_url'],
      diseases: [], // We initialize as empty for now to avoid crashes
    );
  }
}
