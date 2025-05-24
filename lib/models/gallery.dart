class Gallery {
  final int id;
  final String title;
  final String? description;
  final String image;
  final DateTime createdAt;
  final bool isVisible;

  Gallery({
    required this.id,
    required this.title,
    this.description,
    required this.image,
    required this.createdAt,
    required this.isVisible,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      isVisible: json['is_visible'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'is_visible': isVisible,
    };
  }
} 