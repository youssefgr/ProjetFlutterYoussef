import 'package:uuid/uuid.dart';

/// Représente un tag attribué à un fichier (ex : “anime”, “cinematic”)
class FileTag {
  final String id;
  final String tagName;

  FileTag({
    required this.id,
    required this.tagName,
  });

  factory FileTag.newLocal(String tagName) {
    return FileTag(
      id: const Uuid().v4(),
      tagName: tagName,
    );
  }

  factory FileTag.fromJson(Map<String, dynamic> json) {
    return FileTag(
      id: json['id'],
      tagName: json['tagName'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tagName': tagName,
      };
}
