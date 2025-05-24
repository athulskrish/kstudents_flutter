class EntranceNotification {
  final int id;
  final String title;
  final String? description;
  final DateTime deadline;
  final String? link;
  final DateTime publishedDate;
  final bool isPublished;

  EntranceNotification({
    required this.id,
    required this.title,
    this.description,
    required this.deadline,
    this.link,
    required this.publishedDate,
    required this.isPublished,
  });

  factory EntranceNotification.fromJson(Map<String, dynamic> json) {
    return EntranceNotification(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      link: json['link'],
      publishedDate: DateTime.parse(json['published_date']),
      isPublished: json['is_published'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'link': link,
      'published_date': publishedDate.toIso8601String(),
      'is_published': isPublished,
    };
  }
} 