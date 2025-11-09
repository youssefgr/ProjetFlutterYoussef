import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // ✅ Import important pour Uint8List
import 'package:provider/provider.dart';

import '../../../Models/Hajer/mediafile.dart';
import '../../../viewmodels/mediafile_viewmodel.dart';

class PinterestPicker extends StatefulWidget {
  final String mediaItemId;
  const PinterestPicker({super.key, required this.mediaItemId});

  @override
  State<PinterestPicker> createState() => _PinterestPickerState();
}

class _PinterestPickerState extends State<PinterestPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<PinterestImage> _searchResults = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    'wallpaper', 'nature', 'art', 'design', 'fashion',
    'food', 'travel', 'architecture', 'minimal', 'aesthetic'
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 600,
        child: Column(
          children: [
            // Titre
            Text(
              '🔍 Recherche Pinterest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                hintText: 'Ex: wallpaper nature, aesthetic art...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.red),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (_) => _performSearch(),
            ),

            // Suggestions
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _suggestions
                  .map((keyword) => ActionChip(
                label: Text(keyword,
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.red.withOpacity(0.7),
                onPressed: () {
                  _searchController.text = keyword;
                  _performSearch();
                },
              ))
                  .toList(),
            ),

            // Résultats ou message
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.red))
                  : _searchResults.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 60, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          _searchController.text.isEmpty
              ? 'Recherchez des images Pinterest\n(ex: "wallpaper", "art", "design")'
              : 'Aucun résultat pour "${_searchController.text}"\nEssayez d\'autres mots-clés',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final image = _searchResults[index];
        return GestureDetector(
          onTap: () => _importImage(image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  image.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      ),
                    ),
                    child: Text(
                      'Importer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔥 API Pinterest (version simulée)
  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      await _simulatePinterestAPI(_searchController.text);
    } catch (e) {
      print('❌ Erreur recherche Pinterest: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de recherche: $e')),
      );
    }
  }

  // 🔥 SIMULATION d'API Pinterest
  Future<void> _simulatePinterestAPI(String query) async {
    await Future.delayed(Duration(seconds: 2));

    final mockImages = {
      'wallpaper': [
        PinterestImage(
          id: '1',
          thumbnailUrl: 'https://picsum.photos/300/400?random=1',
          originalUrl: 'https://picsum.photos/1200/1600?random=1',
          title: 'Wallpaper Nature',
        ),
        PinterestImage(
          id: '2',
          thumbnailUrl: 'https://picsum.photos/300/400?random=2',
          originalUrl: 'https://picsum.photos/1200/1600?random=2',
          title: 'Abstract Wallpaper',
        ),
      ],
      'nature': [
        PinterestImage(
          id: '3',
          thumbnailUrl: 'https://picsum.photos/300/400?random=3',
          originalUrl: 'https://picsum.photos/1200/1600?random=3',
          title: 'Forest Landscape',
        ),
      ],
      'art': [
        PinterestImage(
          id: '4',
          thumbnailUrl: 'https://picsum.photos/300/400?random=4',
          originalUrl: 'https://picsum.photos/1200/1600?random=4',
          title: 'Modern Art',
        ),
      ],
    };

    setState(() {
      _searchResults = mockImages[query.toLowerCase()] ?? [];
      _isLoading = false;
    });

    if (_searchResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun résultat pour "$query"')),
      );
    }
  }

  // 🔥 CORRECTION : IMPORT RÉEL VERS LE VIEWMODEL
  Future<void> _importImage(PinterestImage image) async {
    try {
      print('📥 Importation: ${image.title}');

      // ✅ Télécharger l'image depuis l'URL
      final bytes = await _downloadImage(image.originalUrl);

      // ✅ Obtenir le ViewModel et importer
      final mediaFileVM = Provider.of<MediaFileViewModel>(context, listen: false);

      await mediaFileVM.addFromBytes(
        mediaItemId: widget.mediaItemId,
        fileName: 'pinterest_${image.id}.jpg',
        bytes: bytes,
        type: FileType.poster,
        removeBackground: false,
      );

      // ✅ Fermer le dialog et montrer le succès
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${image.title}" importé avec succès!'),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('❌ Erreur import Pinterest: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur import: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ CORRECTION : Uint8List au lieu de Unit8List
  Future<Uint8List> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erreur téléchargement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}

class PinterestImage {
  final String id;
  final String thumbnailUrl;
  final String originalUrl;
  final String title;

  PinterestImage({
    required this.id,
    required this.thumbnailUrl,
    required this.originalUrl,
    required this.title,
  });
}