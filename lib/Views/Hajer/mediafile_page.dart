import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Models/Hajer/mediafile.dart';
import '../../viewmodels/mediafile_viewmodel.dart';
import '../../utils/supabase_manager.dart';
import 'widgets/drive_picker_pro.dart';
import 'widgets/pinterest_picker.dart';
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

  // pour le menu FAB
  bool _fabOpen = false;

  static const String defaultMediaItemId =
      '00000000-0000-0000-0000-000000000001';

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
        // snackbars d’erreur / info
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (vm.error != null && vm.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  vm.error!,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            vm.error = null;
          } else if (vm.infoMessage != null && vm.infoMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vm.infoMessage!)),
            );
            vm.infoMessage = null;
          }
        });

        // regrouper les fichiers par FileType → sections horizontales
        final Map<FileType, List<MediaFile>> grouped = {};
        for (final f in vm.files) {
          grouped.putIfAbsent(f.filetype, () => []).add(f);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF05030A), // noir profond style camarade
          appBar: AppBar(
            backgroundColor: const Color(0xFF05030A),
            elevation: 0,
            title: const Text(
              'Media Manager App',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                tooltip: _useRemoveBg
                    ? 'Remove.bg activé'
                    : 'Remove.bg désactivé',
                icon: Icon(
                  Icons.auto_fix_high_outlined,
                  color: _useRemoveBg ? Colors.cyanAccent : Colors.white70,
                ),
                onPressed: () {
                  setState(() => _useRemoveBg = !_useRemoveBg);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _useRemoveBg
                            ? '🧼 Remove.bg ACTIVÉ pour les nouveaux uploads'
                            : '❌ Remove.bg DÉSACTIVÉ',
                      ),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                alignment: Alignment.centerLeft,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'My Cloud Media',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          body: vm.loading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
              : vm.files.isEmpty
              ? const Center(
            child: Text(
              'Aucun fichier dans ton cloud.\nAjoute des médias depuis Pinterest, Drive ou ta galerie 📸',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          )
              : _buildSections(grouped),
          floatingActionButton: _buildFabMenu(),
        );
      },
    );
  }

  // ======================= UI PRINCIPALE =======================

  Widget _buildSections(Map<FileType, List<MediaFile>> grouped) {
    // ordre fixe des sections, comme Movies / Series / Anime
    final orderedTypes = [
      FileType.poster,
      FileType.screenshot,
      FileType.fanArt,
      FileType.wallpaper,
      FileType.meme,
      FileType.cosplay,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final type in orderedTypes)
            if (grouped[type]?.isNotEmpty ?? false)
              _buildHorizontalSection(type, grouped[type]!),
        ],
      ),
    );
  }

  // label + couleur dans le style de la page Media Collection
  String _sectionTitle(FileType type) {
    switch (type) {
      case FileType.poster:
        return 'Posters';
      case FileType.screenshot:
        return 'Screenshots';
      case FileType.fanArt:
        return 'Fan Arts';
      case FileType.wallpaper:
        return 'Wallpapers';
      case FileType.meme:
        return 'Memes';
      case FileType.cosplay:
        return 'Cosplay';
    }
  }

  Color _sectionColor(FileType type) {
    switch (type) {
      case FileType.poster:
        return const Color(0xFFFFA726); // orange Movies
      case FileType.screenshot:
        return const Color(0xFF42A5F5); // bleu Series
      case FileType.fanArt:
        return const Color(0xFFAB47BC); // violet Anime
      case FileType.wallpaper:
        return const Color(0xFF66BB6A); // vert
      case FileType.meme:
        return const Color(0xFFFF7043); // orange plus chaud
      case FileType.cosplay:
        return const Color(0xFFEC407A); // rose
    }
  }

  Widget _buildHorizontalSection(FileType type, List<MediaFile> files) {
    final title = _sectionTitle(type);
    final color = _sectionColor(type);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 0, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre style "Movies | 20"
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '  |  ${files.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _buildPosterCard(files[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterCard(MediaFile file) {
    final tags = (file.autotags ?? []).take(2).toList();
    final hasRemoveBg = file.filename.toLowerCase().contains('no_bg_');

    return GestureDetector(
      onTap: () => _showFullScreen(context, file),
      child: Hero(
        tag: file.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 135,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  file.fileurl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),

                // petit badge Remove.bg
                if (hasRemoveBg)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'no BG',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // tags rapides
                if (tags.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tags.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),

                // overlay bas comme sur le mock
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          file.filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '❤️ ${file.likescount}   ⬇️ ${file.downloadcount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================= FULL SCREEN =======================

  void _showFullScreen(BuildContext context, MediaFile f) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
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
              Positioned(
                top: 60,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Text(
                      f.filename,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
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
                            backgroundColor: Colors.deepPurpleAccent
                                .withOpacity(0.85),
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
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
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

  // ======================= FAB MENU IMPORT =======================

  Widget _buildFabMenu() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // mini FABs
          if (_fabOpen) ...[
            Positioned(
              bottom: 120,
              right: 0,
              child: _miniFab(
                icon: Icons.cloud_download,
                label: 'Drive',
                color: Colors.blueAccent,
                onTap: () {
                  setState(() => _fabOpen = false);
                  _importFromDriveDialog();
                },
              ),
            ),
            Positioned(
              bottom: 70,
              right: 0,
              child: _miniFab(
                icon: Icons.photo_library_outlined,
                label: 'Local',
                color: Colors.greenAccent,
                onTap: () {
                  setState(() => _fabOpen = false);
                  _pickLocalAndUpload();
                },
              ),
            ),
            Positioned(
              bottom: 20,
              right: 70,
              child: _miniFab(
                icon: Icons.image_search,
                label: 'Pinterest',
                color: Colors.pinkAccent,
                onTap: () {
                  setState(() => _fabOpen = false);
                  _importFromPinterest();
                },
              ),
            ),
          ],

          // FAB principal
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.deepPurpleAccent,
              onPressed: () => setState(() => _fabOpen = !_fabOpen),
              child: AnimatedRotation(
                turns: _fabOpen ? 0.125 : 0.0, // petit rotate
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniFab({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        FloatingActionButton.small(
          backgroundColor: color,
          heroTag: '${label}_fab',
          onPressed: onTap,
          child: Icon(icon, color: Colors.black),
        ),
      ],
    );
  }

  // ======================= IMPORTS =======================

  Future<void> _pickLocalAndUpload() async {
    final x =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;

    final safeMediaItemId =
    (widget.mediaItemId.isEmpty) ? defaultMediaItemId : widget.mediaItemId;

    await context.read<MediaFileViewModel>().addFromLocal(
      mediaItemId: safeMediaItemId,
      filePath: x.path,
      type: FileType.poster,
      removeBackground: _useRemoveBg,
    );

    await context.read<MediaFileViewModel>().load(widget.mediaItemId);
  }

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
              const SnackBar(
                  content:
                  Text("⚠️ Fichier Drive sans ID — import impossible.")),
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
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("✅ Importé depuis Drive : $safeFileName")),
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

  Future<void> _importFromPinterest() async {
    await showDialog(
      context: context,
      builder: (ctx) => PinterestPicker(mediaItemId: widget.mediaItemId),
    );
  }
}
