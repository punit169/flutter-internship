class Note {
  String title;
  String content;
  DateTime date;
  DateTime? reminderDate;

  Note({
    required this.title,
    required this.content,
    required this.date,
    this.reminderDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        reminderDate: json['reminderDate'] != null
            ? DateTime.tryParse(json['reminderDate'])
            : null,
      );
}

class TodoTask {
  String title;
  bool isDone;
  DateTime createdAt;
  DateTime? reminderDate;

  TodoTask({
    required this.title,
    this.isDone = false,
    DateTime? createdAt,
    this.reminderDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
      };

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
        title: json['title'] ?? '',
        isDone: json['isDone'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        reminderDate: json['reminderDate'] != null
            ? DateTime.tryParse(json['reminderDate'])
            : null,
      );
}

