class Note {
  final int id;
  final String title;
  final String module;
  final int degree;
  final String degreeName;
  final int semester;
  final int year;
  final int university;
  final String universityName;
  final String file;

  Note({
    required this.id,
    required this.title,
    required this.module,
    required this.degree,
    required this.degreeName,
    required this.semester,
    required this.year,
    required this.university,
    required this.universityName,
    required this.file,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      module: json['module'],
      degree: json['degree'],
      degreeName: json['degree_name'],
      semester: json['semester'],
      year: json['year'],
      university: json['university'],
      universityName: json['university_name'],
      file: json['file'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'module': module,
      'degree': degree,
      'degree_name': degreeName,
      'semester': semester,
      'year': year,
      'university': university,
      'university_name': universityName,
      'file': file,
    };
  }
} 