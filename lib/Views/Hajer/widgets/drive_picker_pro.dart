import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;
import '../../../utils/supabase_manager.dart';

/// 🧠 DrivePickerPro : affiche les images du Google Drive connecté
/// Permet à l’utilisateur de choisir un fichier pour import dans Supabase Storage.
class DrivePickerPro extends StatefulWidget {
  final Function(gdrive.File file) onSelect;
  const DrivePickerPro({super.key, required this.onSelect});

  @override
  State<DrivePickerPro> createState() => _DrivePickerProState();
}

class _DrivePickerProState extends State<DrivePickerPro> {
  bool _loading = true;
  String? _error;
  List<gdrive.File> _files = [];

  @override
  void initState() {
    super.initState();
    _loadDriveFiles();
  }

  /// 🔁 Récupère la liste des fichiers image du Drive Google connecté
  Future<void> _loadDriveFiles() async {
    try {
      final client = await SupabaseManager.getGoogleAuthClient();
      if (client == null) {
        setState(() => _error =
            "❌ Aucun token Google détecté. Connecte-toi via Supabase Auth avant d’accéder à ton Drive.");
        return;
      }

      debugPrint("🟢 Client Google Drive initialisé, récupération des fichiers...");
      final api = gdrive.DriveApi(client);

      final res = await api.files.list(
        q: "mimeType contains 'image/' and trashed=false",
        $fields: "files(id,name,thumbnailLink,mimeType,size)",
        pageSize: 30,
      );

      // 🧹 On filtre les fichiers sans ID ou sans miniature (plus propres pour l'affichage)
      setState(() {
        _files = (res.files ?? [])
            .where((f) => f.id != null && (f.mimeType?.startsWith('image/') ?? false))
            .toList();
        _loading = false;
      });

      debugPrint("📂 ${_files.length} fichiers trouvés dans Drive");
      for (final f in _files) {
        debugPrint("➡️ ${f.name} (${f.id})");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      debugPrint('❌ Erreur chargement Drive: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importer depuis Google Drive'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Erreur : $_error'))
                : _files.isEmpty
                    ? const Center(
                        child: Text(
                          '📭 Aucun fichier image trouvé dans ton Drive.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : GridView.builder(
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
                              // ⚠️ Vérifie que le fichier a bien un ID valide
                              if (f.id == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("⚠️ Fichier Drive invalide (id manquant).")),
                                );
                                return;
                              }

                              Navigator.pop(context);
                              widget.onSelect(f);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("✅ Importé depuis Drive : ${f.name ?? 'sans nom'}")),
                              );
                            },
                            child: GridTile(
                              footer: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(3),
                                child: Text(
                                  f.name ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  f.thumbnailLink ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 40),
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
