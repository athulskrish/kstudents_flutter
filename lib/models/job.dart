class Job {
  final int id;
  final String title;
  final String description;
  final DateTime lastDate;
  final DateTime updatedAt;
  final bool isPublished;
  final int createdBy;
  final String? createdByUsername;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.lastDate,
    required this.updatedAt,
    required this.isPublished,
    required this.createdBy,
    this.createdByUsername,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      lastDate: DateTime.parse(json['last_date']),
      updatedAt: DateTime.parse(json['updated_at']),
      isPublished: json['is_published'],
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'last_date': lastDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_published': isPublished,
    };
  }
} 