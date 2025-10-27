import 'package:uuid/uuid.dart';

/// Représente un album cloud partagé (créé par Hajer)
class SharedAlbum {
  final String id;
  final String albumId;
  final List<String> sharedWithUserIds;
  final DateTime createdDate;
  final String shareCode;

  SharedAlbum({
    required this.id,
    required this.albumId,
    required this.sharedWithUserIds,
    required this.createdDate,
    required this.shareCode,
  });

  factory SharedAlbum.newLocal({
    required String albumId,
    required List<String> sharedWithUserIds,
  }) {
    return SharedAlbum(
      id: const Uuid().v4(),
      albumId: albumId,
      sharedWithUserIds: sharedWithUserIds,
      createdDate: DateTime.now(),
      shareCode: const Uuid().v4().substring(0, 8),
    );
  }

  factory SharedAlbum.fromJson(Map<String, dynamic> json) {
    return SharedAlbum(
      id: json['id'],
      albumId: json['albumId'],
      sharedWithUserIds: List<String>.from(json['sharedWithUserIds'] ?? []),
      createdDate: DateTime.parse(json['createdDate']),
      shareCode: json['shareCode'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'albumId': albumId,
        'sharedWithUserIds': sharedWithUserIds,
        'createdDate': createdDate.toIso8601String(),
        'shareCode': shareCode,
      };
}
