class AdSlider {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final String backgroundColor;
  final String textColor;
  final int position;

  AdSlider({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
    required this.backgroundColor,
    required this.textColor,
    required this.position,
  });

  factory AdSlider.fromJson(Map<String, dynamic> json) {
    return AdSlider(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image'],
      linkUrl: json['link_url'],
      backgroundColor: json['background_color'] ?? '#2563EB',
      textColor: json['text_color'] ?? '#FFFFFF',
      position: json['position'] ?? 0,
    );
  }
} 