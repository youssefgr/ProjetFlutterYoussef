import 'package:uuid/uuid.dart';

/// Enum des types de fichiers définis par Hajer
enum FileType { poster, fanArt, cosplay, screenshot, meme, wallpaper }

/// Représente un fichier média lié à un MediaItem (Akram)
class MediaFile {
  final String id;
  final String userid; // Relation future vers Maamoune (statique pour l'instant)
  final String mediaitemid;
  final String filename;
  final FileType filetype;
  final String fileurl;
  final String? thumbnailurl;
  final int? filesize;
  final int downloadcount;
  final DateTime uploaddate;
  final List<String> appliedfilters;
  final int likescount;

  MediaFile({
    required this.id,
    required this.userid,
    required this.mediaitemid,
    required this.filename,
    required this.filetype,
    required this.fileurl,
    this.thumbnailurl,
    this.filesize,
    this.downloadcount = 0,
    DateTime? uploaddate,
    this.appliedfilters = const [],
    this.likescount = 0,
  }) : uploaddate = uploaddate ?? DateTime.now();

  /// Factory pour créer un fichier local (avant insertion Supabase)
  factory MediaFile.newLocal({
    required String mediaitemid,
    required String filename,
    required FileType filetype,
    required String fileurl,
  }) {
    final safeMediaItemId =
        (mediaitemid.isEmpty || mediaitemid == '00000000-0000-0000-0000-000000000001')
            ? 'STATIC_MEDIAITEM_ID'
            : mediaitemid;

    return MediaFile(
      id: const Uuid().v4(),
      userid: '00000000-0000-0000-0000-000000000001',
      mediaitemid: safeMediaItemId,
      filename: filename,
      filetype: filetype,
      fileurl: fileurl,
    );
  }

  /// Conversion JSON → objet (pour Supabase)
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'],
      userid: json['userid'],
      mediaitemid: json['mediaitemid'] ?? 'STATIC_MEDIAITEM_ID',
      filename: json['filename'],
      filetype: FileType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['filetype'] ?? '').toLowerCase(),
        orElse: () => FileType.poster,
      ),
      fileurl: json['fileurl'],
      thumbnailurl: json['thumbnailurl'],
      filesize: json['filesize'],
      downloadcount: json['downloadcount'] ?? 0,
      uploaddate: DateTime.tryParse(json['uploaddate'] ?? '') ?? DateTime.now(),
      appliedfilters: List<String>.from(json['appliedfilters'] ?? []),
      likescount: json['likescount'] ?? 0,
    );
  }

  /// Conversion objet → JSON (pour Supabase)
  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'mediaitemid': mediaitemid,
        'filename': filename,
        'filetype': filetype.name,
        'fileurl': fileurl,
        'thumbnailurl': thumbnailurl,
        'filesize': filesize,
        'downloadcount': downloadcount,
        'uploaddate': uploaddate.toIso8601String(),
        'appliedfilters': appliedfilters,
        'likescount': likescount,
      };
}
