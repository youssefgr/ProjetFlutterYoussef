import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;
import '../../../services/drive_service.dart';
import '../../../utils/supabase_manager.dart';

/// 📂 Fenêtre d’import depuis Google Drive
/// Affiche les miniatures des images et gère les erreurs d’authentification.
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

  @override
  void initState() {
    super.initState();
    _loadDriveFiles();
  }

  Future<void> _loadDriveFiles() async {
    try {
      final results = await _driveService.listImages(context, pageSize: 30);
      setState(() {
        _files = results;
        _loading = false;
      });
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        // ✅ Gestion du token expiré — demande une reconnexion Google
        setState(() {
          _error = 'Session Google expirée. Reconnexion nécessaire.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
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
            // ---- HEADER ----
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
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _loadDriveFiles,
                  tooltip: "Rafraîchir la liste",
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- CONTENU ----
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _error != null
                      ? _buildErrorContent()
                      : _files.isEmpty
                          ? _buildEmptyState()
                          : _buildGridView(),
            ),

            // ---- FOOTER ----
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text(
                  'Fermer',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧱 GridView des fichiers Drive
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
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
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
                      f.thumbnailLink ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        color: Colors.black.withOpacity(0.7),
                        child: Text(
                          f.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔁 Affiche un message d’erreur + bouton de reconnexion
  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            _error ?? 'Erreur inconnue.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Se reconnecter à Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await SupabaseManager.signInWithGoogle(context);
              setState(() {
                _loading = true;
                _error = null;
              });
              await _loadDriveFiles();
            },
          ),
        ],
      ),
    );
  }

  /// 📭 Aucun fichier trouvé
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Aucun fichier trouvé dans ton Drive.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}
