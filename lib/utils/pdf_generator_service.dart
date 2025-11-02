import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:projetflutteryoussef/Models/Youssef/purchase_history.dart';

class PdfGeneratorService {
  static Future<void> generateAndSharePurchaseHistoryPDF(
      List<PurchaseRecord> purchases,
      ) async {
    try {
      print('📄 Generating PDF...');

      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
      final currency = '€';

      // Calculate statistics
      final totalSpent = purchases.fold(0.0, (sum, p) => sum + p.total);
      final totalItems = purchases.fold(
        0,
            (sum, p) => sum + p.items.fold(0, (s, item) => s + item.quantity),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Purchase History',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Statistics
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox(
                    'Total Purchases',
                    purchases.length.toString(),
                    PdfColors.blue,
                  ),
                  _buildStatBox(
                    'Total Items',
                    totalItems.toString(),
                    PdfColors.green,
                  ),
                  _buildStatBox(
                    'Total Spent',
                    '${totalSpent.toStringAsFixed(2)} $currency',
                    PdfColors.orange,
                  ),
                ],
              ),

              pw.SizedBox(height: 32),

              // Purchase list
              ...purchases.map((purchase) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Purchase header
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  purchase.id,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  dateFormat.format(purchase.date),
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  'Total',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.Text(
                                  '${purchase.total.toStringAsFixed(2)} $currency',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Items table
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Table(
                          border: pw.TableBorder.all(color: PdfColors.grey300),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(3),
                            1: const pw.FlexColumnWidth(2),
                            2: const pw.FlexColumnWidth(1),
                            3: const pw.FlexColumnWidth(1.5),
                            4: const pw.FlexColumnWidth(1.5),
                          },
                          children: [
                            // Header
                            pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey200,
                              ),
                              children: [
                                _buildTableCell('Item', isHeader: true),
                                _buildTableCell('Category', isHeader: true),
                                _buildTableCell('Qty', isHeader: true),
                                _buildTableCell('Price', isHeader: true),
                                _buildTableCell('Subtotal', isHeader: true),
                              ],
                            ),
                            // Items
                            ...purchase.items.map((item) {
                              return pw.TableRow(
                                children: [
                                  _buildTableCell(item.title),
                                  _buildTableCell(item.category),
                                  _buildTableCell('${item.quantity}'),
                                  _buildTableCell(
                                      '${item.price.toStringAsFixed(2)} $currency'),
                                  _buildTableCell(
                                      '${item.subtotal.toStringAsFixed(2)} $currency'),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Email info
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(8),
                            bottomRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          'Receipt sent to: ${purchase.email}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Footer
              pw.SizedBox(height: 32),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // Save and share
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'purchase_history_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

      print('✅ PDF generated and shared');
    } catch (e) {
      print('❌ Error generating PDF: $e');
      rethrow;
    }
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}