import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_view.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_add.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_detail.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_edit.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_delete.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Stack, Column, Row, Border;
import 'package:path_provider/path_provider.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  List<Expenses> _allExpenses = [];
  List<Expenses> _displayedExpenses = [];
  bool _isLoading = true;
  String _searchQuery = "";
  bool _isSortAsc = true;

  bool get _hasItemsInCart => CartManager().hasItems;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('Expenses')
          .select()
          .order('date', ascending: false);

      print('✅ Données reçues de Supabase : ${data.length} items');

      _allExpenses = data.map((e) {
        return Expenses.fromJson(e);
      }).toList();

      print('✅ Dépenses chargées avec images');
      for (var expense in _allExpenses) {
        print('- ${expense.title}: Amount=${expense.amount}, Image=${expense.imageURL}');
      }

      _applyFilters();
    } catch (e) {
      print('❌ Erreur chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _displayedExpenses = _allExpenses.where((exp) {
      final query = _searchQuery.toLowerCase();
      return exp.title.toLowerCase().contains(query);
    }).toList();

    _displayedExpenses.sort((a, b) =>
    _isSortAsc ? a.price.compareTo(b.price) : b.price.compareTo(a.price));

    print('📊 ${_displayedExpenses.length} items affichés');
    setState(() {});
  }

  Future<void> _generateExcel() async {
    try {
      print('📊 Génération Excel...');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      List<Map<String, dynamic>> purchases = _displayedExpenses.map((exp) => {
        'date': exp.date,
        'price': exp.price,
        'title': exp.title,
        'amount': exp.amount,
        'category': exp.category.name,
      }).toList();

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      final Style headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.fontSize = 12;
      headerStyle.backColor = '#4472C4';
      headerStyle.fontColor = '#FFFFFF';

      sheet.getRangeByName('A1').setText('Date');
      sheet.getRangeByName('B1').setText('Price (€)');
      sheet.getRangeByName('C1').setText('Title');
      sheet.getRangeByName('D1').setText('Amount');
      sheet.getRangeByName('E1').setText('Category');

      sheet.getRangeByName('A1:E1').cellStyle = headerStyle;

      for (int i = 0; i < purchases.length; i++) {
        final row = i + 2;
        sheet.getRangeByIndex(row, 1).setDateTime(purchases[i]['date']);
        sheet.getRangeByIndex(row, 2).setNumber(purchases[i]['price']);
        sheet.getRangeByIndex(row, 3).setText(purchases[i]['title']);
        sheet.getRangeByIndex(row, 4).setNumber(purchases[i]['amount']);
        sheet.getRangeByIndex(row, 5).setText(purchases[i]['category']);
      }

      int totalRow = purchases.length + 2;
      sheet.getRangeByIndex(totalRow, 1).setText('Total');
      sheet.getRangeByIndex(totalRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(totalRow, 2).setFormula(
        '=SUMPRODUCT(B2:B${purchases.length + 1}, D2:D${purchases.length + 1})',
      );
      sheet.getRangeByIndex(totalRow, 2).cellStyle.bold = true;

      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);
      sheet.autoFitColumn(5);

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      final fileName = await showDialog<String>(
        context: context,
        builder: (context) {
          TextEditingController controller = TextEditingController(
            text: "expenses_${DateTime.now().millisecondsSinceEpoch}.xlsx",
          );
          return AlertDialog(
            title: const Text('📁 Save Excel File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter a filename:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "filename.xlsx",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.insert_drive_file),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String name = controller.text.trim();
                  if (!name.endsWith('.xlsx')) {
                    name = '$name.xlsx';
                  }
                  Navigator.pop(context, name);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (fileName == null || fileName.isEmpty) return;

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to get save directory'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ File saved: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshCartBadge() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes dépenses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSortAsc ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: 'Tri par prix',
            onPressed: () {
              setState(() => _isSortAsc = !_isSortAsc);
              _applyFilters();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Voir le panier',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartView()),
                  );
                  // ✨ RELOAD APRÈS ACHAT
                  _loadExpenses();
                  _refreshCartBadge();
                },
              ),
              if (_hasItemsInCart)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une dépense',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpensesAdd()),
              ).then((newExpense) {
                if (newExpense != null) {
                  _loadExpenses();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter en Excel',
            onPressed: _generateExcel,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white70,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildExpenseSection(
              ExpensesCategory.Manga,
              'Manga',
              Colors.red,
            ),
            const SizedBox(height: 16),
            _buildExpenseSection(
              ExpensesCategory.Merchandise,
              'Merchandise',
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildExpenseSection(
              ExpensesCategory.EventTicket,
              'Billets d\'événement',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSection(
      ExpensesCategory category,
      String title,
      Color color,
      ) {
    final sectionExpenses =
    _displayedExpenses.where((exp) => exp.category == category).toList();

    if (sectionExpenses.isEmpty) {
      return _buildEmptySection(title, color);
    }

    // ✨ CALCULATE TOTAL ET AVAILABLE ITEMS
    double totalPrice = sectionExpenses.fold(0, (sum, exp) => sum + exp.price);
    int availableCount =
        sectionExpenses.where((exp) => exp.amount > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${sectionExpenses.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: €${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // ✨ AFFICHER AVAILABLE ITEMS
              if (availableCount < sectionExpenses.length)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.orange,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$availableCount available',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _buildExpenseGrid(sectionExpenses, color),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 45,
                  color: color.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune dépense dans $title',
                  style: TextStyle(
                    color: color.withOpacity(0.75),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseGrid(List<Expenses> expensesList, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SizedBox(width: 6),
          ...List.generate(expensesList.length, (index) {
            final expense = expensesList[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildExpenseCard(expense, color),
            );
          }),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  // ✨ CARTE AVEC OUT OF STOCK DETECTION
  Widget _buildExpenseCard(Expenses expense, Color color) {
    final isOutOfStock = expense.amount <= 0;

    return SizedBox(
      width: 140,
      child: GestureDetector(
        onTap: isOutOfStock
            ? null
            : () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpensesDetail(
                expense: expense,
                onUpdate: (updatedExpense) async {
                  final result = await Navigator.push<Expenses>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpensesEdit(
                        expense: updatedExpense,
                      ),
                    ),
                  );
                  if (result != null) {
                    await _loadExpenses();
                  }
                },
                onDelete: (id) async {
                  showDialog(
                    context: context,
                    builder: (context) => ExpensesDelete(
                      expense: expense,
                      onDelete: () async {
                        await _loadExpenses();
                        _refreshCartBadge();
                      },
                    ),
                  );
                },
              ),
            ),
          );
          await _loadExpenses();
          _refreshCartBadge();
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  children: [
                    // 🖼️ IMAGE DEPUIS SUPABASE
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (expense.imageURL.isNotEmpty)
                              Image.network(
                                expense.imageURL,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Erreur chargement image: $error');
                                  return Container(
                                    color: color.withOpacity(0.1),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: color.withOpacity(0.5),
                                      size: 40,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    print(
                                        '✅ Image chargée: ${expense.title}');
                                    return child;
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress
                                          .expectedTotalBytes !=
                                          null
                                          ? loadingProgress
                                          .cumulativeBytesLoaded /
                                          loadingProgress
                                              .expectedTotalBytes!
                                          : null,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          color),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                color: color.withOpacity(0.1),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: color.withOpacity(0.5),
                                  size: 40,
                                ),
                              ),
                            // Badge catégorie
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  expense.category.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // ✨ BADGE OUT OF STOCK
                            if (isOutOfStock)
                              Container(
                                color: Colors.black.withOpacity(0.6),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.block,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'OUT OF STOCK',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Infos en bas
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          color: isOutOfStock
                              ? Colors.grey.shade100
                              : Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              expense.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isOutOfStock
                                    ? Colors.grey.shade500
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '€${expense.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isOutOfStock
                                        ? Colors.grey.shade400
                                        : color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                // ✨ AFFICHAGE QUANTITÉ
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red.shade100
                                        : color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? '0 left'
                                        : '${expense.amount.toInt()} left',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock
                                          ? Colors.red
                                          : color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ✨ COUCHE DÉSACTIVATION
                if (isOutOfStock)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
