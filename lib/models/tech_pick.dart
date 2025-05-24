class TechPick {
  final int id;
  final String title;
  final String? description;
  final String category;
  final double price;
  final String? imageUrl;
  final String affiliateUrl;
  final String? affiliateCode;
  final double? rating;

  TechPick({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.price,
    this.imageUrl,
    required this.affiliateUrl,
    this.affiliateCode,
    this.rating,
  });

  factory TechPick.fromJson(Map<String, dynamic> json) {
    return TechPick(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category_name'] ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      affiliateUrl: json['affiliate_url'],
      affiliateCode: json['affiliate_code'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }
} 