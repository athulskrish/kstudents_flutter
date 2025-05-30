class Note {
  final int id;
  final String title;
  final String subject;
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
    required this.subject,
    required this.degree,
    required this.degreeName,
    required this.semester,
    required this.year,
    required this.university,
    required this.universityName,
    required this.file,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    // For debugging
    print('Note.fromJson processing: $json');
    
    // Handle the subject field which might come as 'module' or 'subject'
    String subjectValue = '';
    if (json.containsKey('module') && json['module'] != null) {
      subjectValue = json['module'];
    } else if (json.containsKey('subject') && json['subject'] != null) {
      subjectValue = json['subject'];
    }
    
    return Note(
      id: json['id'],
      title: json['title'],
      subject: subjectValue,
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
      'module': subject, // Use module key for compatibility
      'subject': subject, // Include both for flexibility
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