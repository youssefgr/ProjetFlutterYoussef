import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;
import '../../../services/Hajer/drive_service.dart';
import '../../../utils/supabase_manager.dart';

class DrivePickerPro extends StatefulWidget {
  final Function(gdrive.File file) onSelect;
  const DrivePickerPro({super.key, required this.onSelect});

  @override
  State<DrivePickerPro> createState() => _DrivePickerProState();
}

class _DrivePickerProState extends State<DrivePickerPro> {
  final DriveService _driveService = DriveService();
  bool _loading = true;
  String? _error;
  List<gdrive.File> _files = [];
  bool _authRedirected = false;

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
        _authRedirected = false;
      });

      final results = await _driveService.listImages(context, pageSize: 30);
      setState(() {
        _files = results;
        _loading = false;
      });
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        setState(() {
          _authRedirected = true;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔐 Authentification Google requise'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      } else {
        setState(() {
          _error = 'Erreur: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _retryWithReauth() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      await SupabaseManager.forceGoogleReauth(context);
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
    if (_authRedirected) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Redirection vers Google...'),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_download, color: Colors.blue),
          SizedBox(width: 8),
          Expanded( // ✅ CORRECTION : Ajout de Expanded
            child: Text(
              'Importer depuis Google Drive',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorContent()
            : _files.isEmpty
            ? _buildEmptyState()
            : _buildGridView(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        if (_error != null)
          TextButton(
            onPressed: _retryWithReauth,
            child: const Text('Réessayer'),
          ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 50),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error ?? 'Erreur inconnue',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer la connexion'),
            onPressed: _retryWithReauth,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 50, color: Colors.grey),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Aucun fichier image trouvé\n dans votre Drive',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _files.length,
      itemBuilder: (context, i) {
        final f = _files[i];
        return GestureDetector(
          onTap: () {
            if (f.id == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("⚠️ Fichier Drive invalide")),
              );
              return;
            }

            Navigator.pop(context);
            widget.onSelect(f);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "✅ Importé : ${f.name ?? 'sans nom'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image thumbnail
                  Image.network(
                    f.thumbnailLink ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                    ),
                  ),

                  // Overlay avec nom du fichier - CORRIGÉ
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        f.name ?? 'Sans nom',
                        maxLines: 2, // ✅ Permet 2 lignes
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Indicateur de sélection
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}