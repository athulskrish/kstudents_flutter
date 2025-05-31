class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final String? category;
  final String? location;
  final String? link;
  final int? categoryId;
  final int? districtId;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.category,
    this.location,
    this.link,
    this.categoryId,
    this.districtId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'] ?? json['name'],
      description: json['description'],
      date: DateTime.parse(json['date'] ?? json['event_start']),
      category: json['category_name'] ?? json['category']?.toString(),
      location: json['location'] ?? json['place'],
      link: json['link'],
      categoryId: json['category'] is int ? json['category'] : null,
      districtId: json['district'] is int ? json['district'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'description': description,
      'date': date.toIso8601String(),
      'event_start': date.toIso8601String(),
      'category': category,
      'category_name': category,
      'location': location,
      'place': location,
      'link': link,
      'category_id': categoryId,
      'district_id': districtId,
    };
  }
} 