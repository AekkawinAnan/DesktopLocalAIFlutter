class Message {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final List<String>? images;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      if (images != null && images!.isNotEmpty) 'images': images,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      images: json['images'] != null ? List<String>.from(json['images'] as List) : null,
    );
  }
}