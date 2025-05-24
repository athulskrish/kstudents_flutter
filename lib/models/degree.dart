class Degree {
  final int id;
  final String name;
  final int university;
  final String universityName;

  Degree({
    required this.id,
    required this.name,
    required this.university,
    required this.universityName,
  });

  factory Degree.fromJson(Map<String, dynamic> json) {
    return Degree(
      id: json['id'],
      name: json['name'],
      university: json['university'],
      universityName: json['university_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'university': university,
      'university_name': universityName,
    };
  }
} 