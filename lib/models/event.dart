class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final String? category;
  final String? location;
  final String? link;
  final String? map_link;
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
    this.map_link,
    this.categoryId,
    this.districtId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Event.fromJson received: $json');
    try {
      // Get title from either 'title' or 'name' field
      final title = json['title'] ?? json['name'];
      print('DEBUG: Event title/name: $title');
      
      // Get date from either 'date' or 'event_start' field
      final dateStr = json['date'] ?? json['event_start'];
      print('DEBUG: Event date/event_start: $dateStr');
      final date = DateTime.parse(dateStr);
      
      // Get category from 'category_name' or try to convert 'category' to string
      final category = json['category_name'] ?? json['category']?.toString();
      print('DEBUG: Event category: $category');
      
      // Get location from either 'location' or 'place' field
      final location = json['location'] ?? json['place'];
      print('DEBUG: Event location/place: $location');
      
      // Get categoryId if available and is int
      final categoryId = json['category'] is int ? json['category'] : null;
      print('DEBUG: Event categoryId: $categoryId (type: ${json['category'] != null ? json['category'].runtimeType : 'null'})');
      
      // Get districtId if available and is int
      final districtId = json['district'] is int ? json['district'] : null;
      print('DEBUG: Event districtId: $districtId (type: ${json['district'] != null ? json['district'].runtimeType : 'null'})');
      
      final event = Event(
        id: json['id'],
        title: title,
        description: json['description'],
        date: date,
        category: category,
        location: location,
        link: json['link'],
        map_link: json['map_link'],
        categoryId: categoryId,
        districtId: districtId,
      );
      print('DEBUG: Successfully created Event object: $event');
      return event;
    } catch (e) {
      print('DEBUG: Error in Event.fromJson: $e');
      rethrow;
    }
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
      'map_link': map_link,
      'category_id': categoryId,
      'district_id': districtId,
    };
  }
  
  @override
  String toString() {
    return 'Event(id: $id, title: $title, date: $date, category: $category, location: $location, categoryId: $categoryId, districtId: $districtId)';
  }
} 