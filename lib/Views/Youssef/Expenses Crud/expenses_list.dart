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
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_grid_item.dart';
import 'package:projetflutteryoussef/repositories/expenses_repository.dart' as _viewModel;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Stack, Column;
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

      print('Données reçues de Supabase : $data');
      _allExpenses = data.map((e) => Expenses.fromJson(e)).toList();

      print('Dépenses parsées: $_allExpenses');
      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des dépenses : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _displayedExpenses = _allExpenses.where((exp) {
      final query = _searchQuery.toLowerCase();
      return exp.title.toLowerCase().contains(query);
    }).toList();

    _displayedExpenses.sort((a, b) =>
    _isSortAsc ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    print('Nombre d\'éléments affichés: ${_displayedExpenses.length}');
    setState(() {});
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    // iOS does not need external storage permissions
    return true;
  }

  Future<String?> _getDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      final directories =
      await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (directories == null || directories.isEmpty) return null;
      return directories.first.path;
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    return null;
  }

  Future<void> _openExcelFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      print('Cannot open file: ${result.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open file: ${result.message}')),
      );
    }
  }

  Future<void> _generateExcel() async {
    List<Map<String, dynamic>> purchases =
    _displayedExpenses.map((exp) => {
      'date': exp.date,
      'price': exp.price,
      'title': exp.title,
      'amount': exp.amount,
      'category': exp.category.toString(),
    }).toList();

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    sheet.getRangeByName('A1').setText('Date');
    sheet.getRangeByName('B1').setText('Price');
    sheet.getRangeByName('C1').setText('Title');
    sheet.getRangeByName('D1').setText('Amount');
    sheet.getRangeByName('E1').setText('Category');

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
    sheet.getRangeByIndex(totalRow, 6).setFormula(
        '=SUMPRODUCT(B2:B${purchases.length + 1}, D2:D${purchases.length + 1})');

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    final downloadPath = await _getDownloadDirectoryPath();
    if (downloadPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get download directory')),
      );
      return;
    }

    // Ask user for filename
    final fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller =
        TextEditingController(text: "expenses_report.xlsx");
        return AlertDialog(
          title: const Text('Enter file name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Filename with .xlsx"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, controller.text.trim()),
                child: const Text('Save')),
          ],
        );
      },
    );

    if (fileName == null || fileName.isEmpty) return;

    final filePath = '$downloadPath/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel file saved at $filePath')),
    );

    await _openExcelFile(filePath);
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
        actions: [
          IconButton(
            icon: Icon(_isSortAsc ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: 'Tri par prix',
            onPressed: () {
              _isSortAsc = !_isSortAsc;
              _applyFilters();
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Voir le panier',
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const CartView()));
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ExpensesAdd()))
                  .then((newExpense) {
                if (newExpense != null) {
                  _loadExpenses();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter en Excel',
            onPressed: () async {
              await _generateExcel();
            },
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
                _searchQuery = value;
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
            _buildExpenseSection(ExpensesCategory.Manga, 'Manga', Colors.red),
            const SizedBox(height: 16),
            _buildExpenseSection(
                ExpensesCategory.Merchandise, 'Merchandise', Colors.blue),
            const SizedBox(height: 16),
            _buildExpenseSection(
                ExpensesCategory.EventTicket, 'Billets d\'événement', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSection(
      ExpensesCategory category, String title, Color color) {
    final sectionExpenses =
    _displayedExpenses.where((exp) => exp.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$title (${sectionExpenses.length})',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: sectionExpenses.isEmpty
              ? _buildEmptySection(title, color)
              : _buildExpenseGrid(sectionExpenses, color),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 45, color: color.withOpacity(0.5)),
            const SizedBox(height: 6),
            Text(
              'Aucune dépense dans $title',
              style: TextStyle(
                color: color.withOpacity(0.75),
                fontSize: 16,
              ),
            ),
            Text(
              'Ajoute-en une pour commencer !',
              style: TextStyle(
                color: color.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseGrid(List<Expenses> expensesList, Color color) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: expensesList.length,
      itemBuilder: (context, index) {
        final expense = expensesList[index];
        return Container(
          width: 130,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: ExpensesGridItem(
            expense: expense,
            sectionColor: color,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesDetail(
                    expense: expense,
                    onUpdate: (updatedExpense) async {
                      await _viewModel.updateExpense(updatedExpense);
                    },
                    onDelete: (id) async {
                      await _viewModel.deleteExpense(id);
                    },
                  ),
                ),
              );
              await _loadExpenses();
              _refreshCartBadge();
            },
          ),
        );
      },
    );
  }
}
