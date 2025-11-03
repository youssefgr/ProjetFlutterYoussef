import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/Hajer/sharedalbum.dart';
import '../../viewmodels/shared_album_viewmodel.dart';

class SharedAlbumPage extends StatefulWidget {
  final String currentUserId;
  const SharedAlbumPage({super.key, required this.currentUserId});

  @override
  State<SharedAlbumPage> createState() => _SharedAlbumPageState();
}

class _SharedAlbumPageState extends State<SharedAlbumPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SharedAlbumViewModel>().load(widget.currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SharedAlbumViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📸 Albums partagés"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.albums.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun album partagé encore.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: vm.albums.length,
                  itemBuilder: (context, i) {
                    final album = vm.albums[i];
                    return Card(
                      color: Colors.grey[900],
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          "Album ID: ${album.albumId}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "👥 ${album.sharedWithUserIds.join(", ")}\n"
                          "📅 ${album.createdDate.toLocal()}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          "🔗 ${album.shareCode}",
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  /// Création d’un nouvel album partagé
  void _showCreateDialog() {
    final userIdsController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Partager un nouvel album",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: userIdsController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Entrez les IDs utilisateurs séparés par des virgules",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final users = userIdsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .toList();

              final album = SharedAlbum.newLocal(
                albumId: "album_demo_${DateTime.now().millisecondsSinceEpoch}",
                sharedWithUserIds: users,
              );

              await context.read<SharedAlbumViewModel>().create(album);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Partager", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
