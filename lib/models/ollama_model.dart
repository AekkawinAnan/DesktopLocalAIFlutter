class OllamaModel {
  final String name;
  final String modifiedAt;
  final int size;
  final String digest;
  final Map<String, dynamic> details;

  OllamaModel({
    required this.name,
    required this.modifiedAt,
    required this.size,
    required this.digest,
    required this.details,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    return OllamaModel(
      name: json['name'] as String,
      modifiedAt: json['modified_at'] as String,
      size: json['size'] as int,
      digest: json['digest'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'modified_at': modifiedAt,
      'size': size,
      'digest': digest,
      'details': details,
    };
  }
}