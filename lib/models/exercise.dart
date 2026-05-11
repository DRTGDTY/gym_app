class Exercise {
  final int? id;
  final String name;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  static const categories = [
    'chest',
    'back',
    'legs',
    'shoulders',
    'arms',
    'core',
  ];

  static const categoryLabels = {
    'chest': '胸',
    'back': '背',
    'legs': '腿',
    'shoulders': '肩',
    'arms': '手臂',
    'core': '核心',
  };

  static const coreCategories = ['chest', 'back', 'legs'];

  Exercise({
    this.id,
    required this.name,
    required this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        isDeleted: (map['is_deleted'] as int) == 1,
      );

  Exercise copyWith({
    int? id,
    String? name,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as int?,
        name: json['name'] as String,
        category: json['category'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
