import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projetflutteryoussef/Models/Youssef/purchase_history.dart';
import 'package:projetflutteryoussef/utils/purchase_history_service.dart';
import 'package:projetflutteryoussef/utils/pdf_generator_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseHistoryView extends StatefulWidget {
  const PurchaseHistoryView({super.key});

  @override
  State<PurchaseHistoryView> createState() => _PurchaseHistoryViewState();
}

class _PurchaseHistoryViewState extends State<PurchaseHistoryView> {
  List<PurchaseRecord> _purchases = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  double _totalSpending = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      setState(() => _isLoading = true);

      // ✨ GET CURRENT USER ID FROM SUPABASE
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      final String userId = supabaseUser?.id ?? 'anonymous';

      print('📋 Loading purchases for user: $userId');

      // ✨ GET PURCHASES FROM NEW TABLE STRUCTURE
      final purchases = await PurchaseHistoryService.getPurchasesForUser(userId);

      print('📋 Received ${purchases.length} purchases from Supabase');

      // ✨ GROUP ITEMS BY PURCHASE ID (since table now has one row per item)
      Map<String, Map<String, dynamic>> purchaseMap = {};

      for (var purchase in purchases) {
        String purchaseId = (purchase['id'] as String).split('-').take(1).join('-');

        if (!purchaseMap.containsKey(purchaseId)) {
          purchaseMap[purchaseId] = {
            'id': purchaseId,
            'purchase_date': purchase['purchase_date'],
            'email': purchase['email'],
            'items': [],
            'total': 0.0,
          };
        }

        // ✨ FIX: Handle null values safely
        double itemTotal = 0.0;
        if (purchase['total'] != null) {
          itemTotal = (purchase['total'] as num).toDouble();
        }

        purchaseMap[purchaseId]!['items'].add({
          'id': purchase['id'],
          'title': purchase['item_name'] ?? 'Unknown',
          'category': purchase['category'] ?? 'Unknown',
          'quantity': purchase['quantity'] ?? 1,
          'price': (purchase['price'] as num?)?.toDouble() ?? 0.0,
        });

        double currentTotal = (purchaseMap[purchaseId]!['total'] as num).toDouble();
        purchaseMap[purchaseId]!['total'] = currentTotal + itemTotal;
      }

      // ✨ CONVERT TO PURCHASERECORD
      final purchaseRecords = purchaseMap.values.map((p) {
        List<PurchaseItem> items = [];
        for (var item in (p['items'] as List)) {
          items.add(PurchaseItem.fromJson(item));
        }

        return PurchaseRecord(
          id: p['id'] as String,
          date: DateTime.parse(p['purchase_date'] as String),
          items: items,
          total: p['total'] as double,
          email: p['email'] as String,
          userId: userId,
        );
      }).toList();

      // ✨ SORT BY DATE (newest first)
      purchaseRecords.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _purchases = purchaseRecords;
        _totalSpending = purchaseRecords.fold(0.0, (sum, p) => sum + p.total);
        _isLoading = false;
      });

      print('✅ Loaded ${_purchases.length} grouped purchases');
    } catch (e) {
      print('❌ Error loading purchases: $e');
      setState(() => _isLoading = false);
    }
  }


  Future<void> _generatePDF() async {
    if (_purchases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No purchases to generate PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      await PdfGeneratorService.generateAndSharePurchaseHistoryPDF(_purchases);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        actions: [
          if (_purchases.isNotEmpty)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Generate PDF',
              onPressed: _isGeneratingPdf ? null : _generatePDF,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No purchases yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your purchase history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildStatistics(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPurchases,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _purchases.length,
                itemBuilder: (context, index) {
                  return _buildPurchaseCard(_purchases[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final totalSpent = _purchases.fold<double>(
      0.0,
          (sum, p) => sum + (p.total ?? 0.0),
    );
    final totalItems = _purchases.fold<int>(
      0,
          (sum, p) => sum + (p.items?.fold<int>(0, (s, item) => s + item.quantity) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Purchases',
            _purchases.length.toString(),
            Icons.shopping_cart,
          ),
          _buildStatItem('Items', totalItems.toString(), Icons.inventory),
          _buildStatItem(
            'Spent',
            '${totalSpent.toStringAsFixed(2)} €',
            Icons.euro,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPurchaseCard(PurchaseRecord? purchase) {
    if (purchase == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(purchase.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${(purchase.total ?? 0.0).toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...(purchase.items ?? []).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                item.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.subtotal.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Receipt sent to: ${purchase.email}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
