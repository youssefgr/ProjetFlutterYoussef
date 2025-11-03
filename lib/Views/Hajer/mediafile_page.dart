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

  static const String defaultMediaItemId =
      '00000000-0000-0000-0000-000000000001'; // ✅ ID par défaut

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (vm.error != null && vm.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vm.error!, style: const TextStyle(color: Colors.white))),
            );
            vm.error = null;
          } else if (vm.infoMessage != null && vm.infoMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vm.infoMessage!)),
            );
            vm.infoMessage = null;
          }
        });

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'My Cloud Media',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Importer depuis Google Drive',
                icon: const Icon(Icons.cloud_download, color: Colors.white),
                onPressed: _importFromDriveDialog,
              ),
              IconButton(
                tooltip: 'Ajouter un fichier local',
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _pickLocalAndUpload,
              ),
              PopupMenuButton(
                color: Colors.grey[900],
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (ctx) => [
                  CheckedPopupMenuItem(
                    value: 'removebg',
                    checked: _useRemoveBg,
                    child: const Text(
                      'Remove.bg à l’upload',
                      style: TextStyle(color: Colors.white),
                    ),
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
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : vm.files.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun fichier disponible',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: vm.files.length,
                     itemBuilder: (ctx, i) {
  final f = vm.files[i];
  final tags = (f.autotags ?? []).take(2).toList(); // 🧠 On limite à 2 tags visibles

  return GestureDetector(
    onTap: () => _showFullScreen(context, f),
    child: Hero(
      tag: f.id,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              f.fileurl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[900],
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image,
                    color: Colors.grey, size: 40),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.filename,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: -6,
                        children: tags
                            .map(
                              (t) => Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                                backgroundColor: Colors.blueGrey.shade700,
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '❤️ ${f.likescount}   ⬇️ ${f.downloadcount}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
},

                    ),
        );
      },
    );
  }

  /// ======================= 🖼️ Vue plein écran =======================
  void _showFullScreen(BuildContext context, MediaFile f) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9), // effet fondu propre
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // === IMAGE ===
            Center(
              child: Hero(
                tag: f.id,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    f.fileurl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),

            // === TITRE + TAGS AUTOMATIQUES ===
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 1.0,
                child: Column(
                  children: [
                    Text(
                      f.filename,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // ✅ affichage des tags auto (venant du modèle)
                    if (f.autotags != null && f.autotags!.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: -4,
                        children: f.autotags!
                            .map(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor:
                                    Colors.deepPurpleAccent.withOpacity(0.8),
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                              ),
                            )
                            .toList(),
                      )
                    else
                      const Text(
                        'Aucun tag détecté 🤔',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // === BOUTON FERMER ===
            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // === BOUTON SUPPRIMER ===
            Positioned(
              bottom: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 32,
                ),
                onPressed: () async {
                  await context.read<MediaFileViewModel>().remove(f);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Fichier supprimé avec succès ✅'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  /// ======================= 🖼️ Upload local =======================
  Future<void> _pickLocalAndUpload() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;

    final safeMediaItemId =
        (widget.mediaItemId.isEmpty) ? defaultMediaItemId : widget.mediaItemId;

    await context.read<MediaFileViewModel>().addFromLocal(
          mediaItemId: safeMediaItemId,
          filePath: x.path,
          type: FileType.poster,
          removeBackground: _useRemoveBg,
          removeBgApiKey: _removeBgKey,
        );

    await context.read<MediaFileViewModel>().load(widget.mediaItemId);
  }

  /// ======================= ☁️ Import Drive =======================
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
              (widget.mediaItemId.isEmpty) ? defaultMediaItemId : widget.mediaItemId;
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
                  context: context,
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

            await context.read<MediaFileViewModel>().load(widget.mediaItemId);
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
