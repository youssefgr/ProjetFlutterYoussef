import 'package:flutter/material.dart';
import '../../../services/drive_service.dart';

class DriveImportDialog extends StatefulWidget {
  final Function(String fileId, String fileName) onImport;
  const DriveImportDialog({super.key, required this.onImport});

  @override
  State<DriveImportDialog> createState() => _DriveImportDialogState();
}

class _DriveImportDialogState extends State<DriveImportDialog> {
  final DriveService _driveService = DriveService();
  bool _loading = true;
  String? _error;
  List<dynamic> _files = [];

  @override
  void initState() {
    super.initState();
    _loadDriveFiles();
  }

  Future<void> _loadDriveFiles() async {
    try {
      final results = await _driveService.listImages(pageSize: 25);
      setState(() {
        _files = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importer depuis Google Drive'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Erreur : $_error'))
                : _files.isEmpty
                    ? const Center(child: Text('Aucun fichier trouvé dans ton Drive.'))
                    : GridView.builder(
                        itemCount: _files.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemBuilder: (ctx, i) {
                          final f = _files[i];
                          return GestureDetector(
                            onTap: () {
                              widget.onImport(f.id ?? '', f.name ?? '');
                              Navigator.pop(context);
                            },
                            child: GridTile(
                              footer: Container(
                                padding: const EdgeInsets.all(4),
                                color: Colors.black54,
                                child: Text(
                                  f.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  f.thumbnailLink ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
