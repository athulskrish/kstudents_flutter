class QuestionPaper {
  final int id;
  final int degree;
  final String degreeName;
  final int semester;
  final String subject;
  final String filePath;
  final int year;
  final int universityId;
  final String universityName;
  final bool isPublished;

  QuestionPaper({
    required this.id,
    required this.degree,
    required this.degreeName,
    required this.semester,
    required this.subject,
    required this.filePath,
    required this.year,
    required this.universityId,
    required this.universityName,
    required this.isPublished,
  });

  factory QuestionPaper.fromJson(Map<String, dynamic> json) {
    return QuestionPaper(
      id: json['id'],
      degree: json['degree'],
      degreeName: json['degree_name'],
      semester: json['semester'],
      subject: json['subject'],
      filePath: json['file_path'],
      year: json['year'],
      universityId: json['university_id'],
      universityName: json['university_name'],
      isPublished: json['is_published'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'degree': degree,
      'degree_name': degreeName,
      'semester': semester,
      'subject': subject,
      'file_path': filePath,
      'year': year,
      'university_id': universityId,
      'university_name': universityName,
      'is_published': isPublished,
    };
  }
} 