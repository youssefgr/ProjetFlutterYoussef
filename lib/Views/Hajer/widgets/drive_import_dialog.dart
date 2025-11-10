import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;
import '../../../services/Hajer/drive_service.dart';
import '../../../utils/supabase_manager.dart';

class DriveImportDialog extends StatefulWidget {
  final Function(gdrive.File file) onSelect;
  const DriveImportDialog({super.key, required this.onSelect});

  @override
  State<DriveImportDialog> createState() => _DriveImportDialogState();
}

class _DriveImportDialogState extends State<DriveImportDialog> {
  final DriveService _driveService = DriveService();
  bool _loading = true;
  String? _error;
  List<gdrive.File> _files = [];
  bool _needsReauth = false;

  @override
  void initState() {
    super.initState();
    _loadDriveFiles();
  }

  Future<void> _loadDriveFiles() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _needsReauth = false;
      });

      final results = await _driveService.listImages(context, pageSize: 30);
      setState(() {
        _files = results;
        _loading = false;
      });
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        setState(() {
          _error = 'Session Google expirée. Veuillez vous reconnecter.';
          _needsReauth = true;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleReauth() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
        _needsReauth = false;
      });

      await SupabaseManager.signInWithGoogle(context);
      await _loadDriveFiles();
    } catch (e) {
      setState(() {
        _error = 'Échec de la reconnexion: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 550, maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📁 Import depuis Google Drive',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (!_needsReauth)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _loadDriveFiles,
                    tooltip: "Rafraîchir",
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _error != null
                  ? _buildErrorContent()
                  : _files.isEmpty
                  ? _buildEmptyState()
                  : _buildGridView(),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text('Fermer', style: TextStyle(color: Colors.redAccent)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _needsReauth ? Icons.login : Icons.warning,
            color: _needsReauth ? Colors.blueAccent : Colors.orangeAccent,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Erreur inconnue',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_needsReauth)
            ElevatedButton.icon(
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Se reconnecter à Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleReauth,
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer'),
              onPressed: _loadDriveFiles,
            ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (ctx, i) {
        final f = _files[i];
        return GestureDetector(
          onTap: () {
            widget.onSelect(f);
            Navigator.pop(context);
          },
          child: _buildFileThumbnail(f),
        );
      },
    );
  }

  Widget _buildFileThumbnail(gdrive.File file) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              file.thumbnailLink ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white54, size: 32),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  file.name ?? 'Sans nom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, color: Colors.white54, size: 40),
          SizedBox(height: 10),
          Text(
            'Aucun fichier image trouvé\n dans votre Drive',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}