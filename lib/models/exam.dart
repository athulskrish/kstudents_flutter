class Exam {
  final int id;
  final String examName;
  final DateTime examDate;
  final String examUrl;
  final int degreeName;
  final String degreeNameStr;
  final String semester;
  final int admissionYear;
  final int university;
  final String universityName;
  final bool isPublished;

  Exam({
    required this.id,
    required this.examName,
    required this.examDate,
    required this.examUrl,
    required this.degreeName,
    required this.degreeNameStr,
    required this.semester,
    required this.admissionYear,
    required this.university,
    required this.universityName,
    required this.isPublished,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    int parseDegreeId(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('DEBUG: Could not parse degree_name as int: $value');
          return 0; // Default ID when the string can't be parsed
        }
      }
      return 0;
    }

    return Exam(
      id: json['id'],
      examName: json['exam_name'],
      examDate: DateTime.parse(json['exam_date']),
      examUrl: json['exam_url'],
      degreeName: parseDegreeId(json['degree_name']),
      degreeNameStr: json['degree_name_str'] ?? (json['degree_name'] is String ? json['degree_name'] : ''),
      semester: json['semester'].toString(),
      admissionYear: json['admission_year'] is int ? json['admission_year'] : int.parse(json['admission_year'].toString()),
      university: json['university'] is int ? json['university'] : int.parse(json['university'].toString()),
      universityName: json['university_name'],
      isPublished: json['is_published'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_name': examName,
      'exam_date': examDate.toIso8601String(),
      'exam_url': examUrl,
      'degree_name': degreeName,
      'degree_name_str': degreeNameStr,
      'semester': semester,
      'admission_year': admissionYear,
      'university': university,
      'university_name': universityName,
      'is_published': isPublished,
    };
  }
} 