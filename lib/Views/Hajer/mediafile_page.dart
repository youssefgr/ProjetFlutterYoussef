import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../Models/Hajer/mediafile.dart';
import '../../viewmodels/mediafile_viewmodel.dart';
import '../../utils/supabase_manager.dart';
import 'widgets/drive_picker_pro.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;

class MediaFilePage extends StatefulWidget {
  final String mediaItemId;
  const MediaFilePage({super.key, required this.mediaItemId});

  @override
  State<MediaFilePage> createState() => _MediaFilePageState();
}

class _MediaFilePageState extends State<MediaFilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _useRemoveBg = false;
  String? _removeBgKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaFileViewModel>().load(widget.mediaItemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaFileViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cloud Management'),
            actions: [
              IconButton(
                tooltip: 'Importer depuis Google Drive',
                icon: const Icon(Icons.cloud_download),
                onPressed: _importFromDriveDialog,
              ),
              IconButton(
                tooltip: 'Ajouter un fichier local',
                icon: const Icon(Icons.add),
                onPressed: _pickLocalAndUpload,
              ),
              PopupMenuButton(
                itemBuilder: (ctx) => [
                  CheckedPopupMenuItem(
                    value: 'removebg',
                    checked: _useRemoveBg,
                    child: const Text('Remove.bg à l’upload'),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'removebg') {
                    setState(() => _useRemoveBg = !_useRemoveBg);
                  }
                },
              ),
            ],
          ),
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : vm.error != null
                  ? Center(child: Text('Erreur : ${vm.error}'))
                  : vm.files.isEmpty
                      ? const Center(child: Text('Aucun fichier disponible.'))
                      : ListView.builder(
                          itemCount: vm.files.length,
                          itemBuilder: (ctx, i) {
                            final f = vm.files[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    f.fileurl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, _, __) =>
                                        const Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                                title: Text(
                                  f.filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '❤️ ${f.likescount}   ⬇️ ${f.downloadcount}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Supprimer',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    await vm.remove(f);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Fichier supprimé ✅')),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
        );
      },
    );
  }

  /// 🖼️ Sélection et upload d’un fichier local
  Future<void> _pickLocalAndUpload() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;

    final safeMediaItemId =
        (widget.mediaItemId.isEmpty || widget.mediaItemId == '00000000-0000-0000-0000-000000000001')
            ? 'STATIC_MEDIAITEM_ID'
            : widget.mediaItemId;

    await context.read<MediaFileViewModel>().addFromLocal(
          mediaItemId: safeMediaItemId,
          filePath: x.path,
          type: FileType.poster,
          removeBackground: _useRemoveBg,
          removeBgApiKey: _removeBgKey,
        );
  }

  /// ☁️ Import de fichiers depuis Google Drive
  Future<void> _importFromDriveDialog() async {
    if (!SupabaseManager.isLoggedIn) {
      await SupabaseManager.signInWithGoogle(context);
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => DrivePickerPro(
        onSelect: (gdrive.File file) async {
          final safeMediaItemId =
              (widget.mediaItemId.isEmpty || widget.mediaItemId == '00000000-0000-0000-0000-000000000001')
                  ? 'STATIC_MEDIAITEM_ID'
                  : widget.mediaItemId;

          final safeFileId = file.id ?? '';
          final safeFileName = file.name ?? 'sans_nom.jpg';

          if (safeFileId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("⚠️ Fichier Drive sans ID — import impossible.")),
            );
            return;
          }

          try {
            await context.read<MediaFileViewModel>().addFromDrive(
                  mediaItemId: safeMediaItemId,
                  driveFileId: safeFileId,
                  driveFileName: safeFileName,
                  type: FileType.poster,
                  removeBackground: _useRemoveBg,
                  removeBgApiKey: _removeBgKey,
                );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ Importé depuis Drive : $safeFileName")),
            );
          } catch (e) {
            debugPrint("❌ Erreur import Drive : $e");
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur import Drive : $e")),
            );
          }
        },
      ),
    );
  }
}
