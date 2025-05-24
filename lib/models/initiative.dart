class Initiative {
  final int id;
  final String name;
  final String? description;
  final String? link;
  final String? photo;
  final DateTime updatedAt;
  final bool isPublished;

  Initiative({
    required this.id,
    required this.name,
    this.description,
    this.link,
    this.photo,
    required this.updatedAt,
    required this.isPublished,
  });

  factory Initiative.fromJson(Map<String, dynamic> json) {
    return Initiative(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      link: json['link'],
      photo: json['photo'],
      updatedAt: DateTime.parse(json['updated_at']),
      isPublished: json['is_published'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'link': link,
      'photo': photo,
      'updated_at': updatedAt.toIso8601String(),
      'is_published': isPublished,
    };
  }
} 