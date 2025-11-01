import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_view.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_add.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_detail.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_grid_item.dart';
import 'package:projetflutteryoussef/repositories/expenses_repository.dart' as _viewModel;
import 'package:supabase_flutter/supabase_flutter.dart';

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
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartView()));
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
                  MaterialPageRoute(
                      builder: (context) => const ExpensesAdd()))
                  .then((newExpense) {
                if (newExpense != null) {
                  _loadExpenses();
                }
              });
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
            _buildExpenseSection(ExpensesCategory.Merchandise, 'Merchandise', Colors.blue),
            const SizedBox(height: 16),
            _buildExpenseSection(ExpensesCategory.EventTicket, 'Billets d\'événement', Colors.yellow),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSection(ExpensesCategory category, String title, Color color) {
    final sectionExpenses = _displayedExpenses.where((exp) => exp.category == category).toList();

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
            // Dans _buildExpenseGrid, lors du tap sur un item
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesDetail(
                    expense: expense,
                    onUpdate: (updatedExpense) async {
                      await _viewModel.updateExpense(updatedExpense);
                      // Supprime _loadExpenses() ici car update déjà fait
                    },
                    onDelete: (id) async {
                      await _viewModel.deleteExpense(id);
                      // Supprime _loadExpenses() ici car delete déjà fait
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
