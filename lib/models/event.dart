class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final String? category;
  final String? location;
  final String? link;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.category,
    this.location,
    this.link,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      location: json['location'],
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'location': location,
      'link': link,
    };
  }
} 