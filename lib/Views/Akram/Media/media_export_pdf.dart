import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../viewmodels/Akram/media_viewmodel.dart';

class MediaExportPDF {
  static Future<void> exportMediaListToPDF(
      BuildContext context,
      MediaViewModel viewModel, {
        String fileName = 'media_collection',
      }) async {
    try {
      // Show loading dialog with progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading images and generating PDF...'),
            ],
          ),
        ),
      );

      // Download images for all media items
      final imageMap = await _downloadAllImages(viewModel.mediaItems);

      // Create PDF document
      final pdf = pw.Document(
        title: 'Media Collection',
        author: 'Media App',
      );

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Media Collection',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total Items: ${viewModel.mediaItems.length}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 30),
                _buildSummarySection(viewModel),
              ],
            );
          },
        ),
      );

      // Group items by status
      final itemsByStatus = {
        'To View': viewModel.getItemsByStatus(MediaViewStatus.toView),
        'Viewing': viewModel.getItemsByStatus(MediaViewStatus.viewing),
        'Viewed': viewModel.getItemsByStatus(MediaViewStatus.viewed),
      };

      // Add pages for each status
      for (final entry in itemsByStatus.entries) {
        if (entry.value.isNotEmpty) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Header(
                      level: 1,
                      child: pw.Text(
                        '${entry.key} (${entry.value.length})',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    ..._buildMediaItemsList(entry.value, imageMap),
                  ],
                );
              },
            ),
          );
        }
      }

      // Close loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<Map<String, Uint8List?>> _downloadAllImages(List<MediaItem> items) async {
    final imageMap = <String, Uint8List?>{};

    // Download images concurrently
    final futures = <Future<void>>[];

    for (final item in items) {
      if (item.imageUrl.isNotEmpty) {
        futures.add(_downloadImage(item.id, item.imageUrl).then((imageBytes) {
          imageMap[item.id] = imageBytes;
        }));
      }
    }

    // Wait for all downloads to complete
    await Future.wait(futures);

    return imageMap;
  }

  static Future<Uint8List?> _downloadImage(String itemId, String imageUrl) async {
    try {
      // Ensure the URL is complete
      String fullUrl = imageUrl;
      if (!imageUrl.startsWith('http')) {
        // If it's a relative path from TMDB, prepend the base URL
        fullUrl = 'https://image.tmdb.org/t/p/w500$imageUrl';
      }

      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to download image for $itemId: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading image for $itemId: $e');
      return null;
    }
  }

  static pw.Widget _buildSummarySection(MediaViewModel viewModel) {
    final statusCounts = {
      'To View': viewModel.getItemsByStatus(MediaViewStatus.toView).length,
      'Viewing': viewModel.getItemsByStatus(MediaViewStatus.viewing).length,
      'Viewed': viewModel.getItemsByStatus(MediaViewStatus.viewed).length,
    };

    final categoryCounts = <String, int>{};
    for (final item in viewModel.mediaItems) {
      final category = item.category.toString().split('.').last;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Status Distribution:'),
        ...statusCounts.entries.map((entry) =>
            pw.Text('  • ${entry.key}: ${entry.value} items')
        ).toList(),
        pw.SizedBox(height: 10),
        pw.Text('Category Distribution:'),
        ...categoryCounts.entries.map((entry) =>
            pw.Text('  • ${entry.key}: ${entry.value} items')
        ).toList(),
      ],
    );
  }

  static List<pw.Widget> _buildMediaItemsList(List<MediaItem> items, Map<String, Uint8List?> imageMap) {
    return items.map((item) =>
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 15),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Image section - use downloaded image or placeholder
              _buildImageWidget(item, imageMap[item.id]),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      item.description.isNotEmpty
                          ? item.description
                          : 'No description available',
                      style: const pw.TextStyle(fontSize: 10),
                      maxLines: 2,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _getStatusColor(item.status),
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Text(
                            item.status.toString().split('.').last,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue400,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Text(
                            item.category.toString().split('.').last,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        if (item.genre != null) ...[
                          pw.SizedBox(width: 5),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green400,
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.Text(
                              item.genre!.toString().split('.').last,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    pw.SizedBox(height: 5),

                    if (item.releaseDate != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Release Date: ${_formatDate(item.releaseDate!)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )
    ).toList();
  }

  static pw.Widget _buildImageWidget(MediaItem item, Uint8List? imageBytes) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        return pw.Container(
          width: 60,
          height: 80,
          child: pw.Image(
            pw.MemoryImage(imageBytes),
            fit: pw.BoxFit.cover,
          ),
        );
      } catch (e) {
        print('Error creating image for ${item.title}: $e');
        return _buildPlaceholderImage(item);
      }
    } else {
      return _buildPlaceholderImage(item);
    }
  }

  static pw.Widget _buildPlaceholderImage(MediaItem item) {
    return pw.Container(
      width: 60,
      height: 80,
      color: PdfColors.grey200,
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Icon(
              _getCategoryIcon(item.category),
              size: 20,
              color: PdfColors.grey400,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'No Image',
              style: pw.TextStyle(
                fontSize: 6,
                color: PdfColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.IconData _getCategoryIcon(MediaCategory category) {
    switch (category) {
      case MediaCategory.movie:
        return pw.IconData(0xE8D6); // Movie icon code
      case MediaCategory.series:
        return pw.IconData(0xE63B); // TV icon code
      case MediaCategory.anime:
        return pw.IconData(0xE84F); // Anime icon code
      case MediaCategory.manga:
        return pw.IconData(0xE865); // Book icon code
      default:
        return pw.IconData(0xE8D6); // Default movie icon
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static PdfColor _getStatusColor(MediaViewStatus status) {
    switch (status) {
      case MediaViewStatus.toView:
        return PdfColors.orange;
      case MediaViewStatus.viewing:
        return PdfColors.blue;
      case MediaViewStatus.viewed:
        return PdfColors.green;
      default:
        return PdfColors.grey;
    }
  }

  // Optional: Method to save PDF to device storage
  static Future<void> _savePdfToFile(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());
      print('PDF saved to: ${file.path}');
    } catch (e) {
      print('Error saving PDF to file: $e');
    }
  }
}