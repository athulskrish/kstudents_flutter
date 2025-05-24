class News {
  final int id;
  final String title;
  final String? slug;
  final String content;
  final String? excerpt;
  final String? image;
  final String? thumbnail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final int createdBy;
  final String? createdByUsername;
  final String? metaTitle;
  final String? metaDescription;
  final String? keywords;
  final int readingTime;
  final int viewsCount;
  final int likesCount;

  News({
    required this.id,
    required this.title,
    this.slug,
    required this.content,
    this.excerpt,
    this.image,
    this.thumbnail,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
    required this.createdBy,
    this.createdByUsername,
    this.metaTitle,
    this.metaDescription,
    this.keywords,
    required this.readingTime,
    required this.viewsCount,
    required this.likesCount,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      excerpt: json['excerpt'],
      image: json['image'],
      thumbnail: json['thumbnail'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isPublished: json['is_published'],
      createdBy: json['created_by'],
      createdByUsername: json['created_by_username'],
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
      keywords: json['keywords'],
      readingTime: json['reading_time'],
      viewsCount: json['views_count'],
      likesCount: json['likes_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'image': image,
      'thumbnail': thumbnail,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_published': isPublished,
      'created_by': createdBy,
      'created_by_username': createdByUsername,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'keywords': keywords,
      'reading_time': readingTime,
      'views_count': viewsCount,
      'likes_count': likesCount,
    };
  }
} 