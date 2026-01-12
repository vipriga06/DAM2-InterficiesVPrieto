class Player {
  final String id;
  final String name;
  final String position;
  final String category;
  final int number;
  final String nationality;
  final String description;
  final String imageUrl;
  final int height;
  final int weight;
  final String birthDate;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    required this.number,
    required this.nationality,
    required this.description,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.birthDate,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      category: json['category'] ?? '',
      number: json['number'] ?? 0,
      nationality: json['nationality'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      birthDate: json['birthDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'category': category,
      'number': number,
      'nationality': nationality,
      'description': description,
      'imageUrl': imageUrl,
      'height': height,
      'weight': weight,
      'birthDate': birthDate,
    };
  }
}
