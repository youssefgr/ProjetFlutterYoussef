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

  /// 🧠 Nouveau champ pour les tags auto-générés par HuggingFace
  final List<String>? autotags;

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
    this.autotags, // ✅ ajouté ici
  }) : uploaddate = uploaddate ?? DateTime.now();

  /// ✅ Factory pour créer un fichier local (avant insertion Supabase)
  factory MediaFile.newLocal({
    required String mediaitemid,
    required String filename,
    required FileType filetype,
    required String fileurl,
  }) {
    // Corrigé : plus jamais de "STATIC_MEDIAITEM_ID"
    final safeMediaItemId = (mediaitemid.isEmpty ||
            mediaitemid.toUpperCase() == 'STATIC_MEDIAITEM_ID' ||
            mediaitemid == 'null')
        ? '00000000-0000-0000-0000-000000000001'
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

  /// ✅ Conversion JSON → objet (pour Supabase)
factory MediaFile.fromJson(Map<String, dynamic> json) {
  final rawId = json['mediaitemid']?.toString() ?? '';
  final safeMediaItemId = (rawId.isEmpty ||
          rawId.toUpperCase() == 'STATIC_MEDIAITEM_ID' ||
          rawId == 'null')
      ? '00000000-0000-0000-0000-000000000001'
      : rawId;

  return MediaFile(
    id: json['id'],
    userid: json['userid'] ?? '00000000-0000-0000-0000-000000000001',
    mediaitemid: safeMediaItemId,
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

    /// ✅ Décodage intelligent des autotags
    autotags: (json['autotags'] is List)
        ? (json['autotags'] as List)
            .expand((e) => e.toString().split(RegExp(r'[,\s]+')))
            .where((tag) => tag.trim().isNotEmpty)
            .map((e) => e.trim())
            .toList()
        : [],
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

        /// ✅ export des tags pour affichage
        'autotags': autotags,
      };
}
