import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'Expenses_crud_uri.dart';
import 'package:projetflutteryoussef/viewmodels/expenses_viewmodel.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_view.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';

class ExpensesList extends StatefulWidget {
   const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}
class _ExpensesListState extends State<ExpensesList> {
  final ExpensesViewModel _viewModel = ExpensesViewModel();

  List<Expenses> _allExpenses = [];
  List<Expenses> _displayedExpenses = [];

  bool _isLoading = true;
  String _searchQuery = "";
  bool _isSortAsc = true;

  void _refreshCartBadge() {
    setState(() {});
  }

  bool get _hasItemsInCart => CartManager().hasItems;

  @override
  void initState() {
    super.initState();
    _viewModel.onExpensesUpdated = _onExpensesUpdated;
    _loadExpenses();
  }

  void _onExpensesUpdated() {
    _allExpenses = _viewModel.expensesList;
    _applyFilters();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    await _viewModel.loadExpenses();
    _allExpenses = _viewModel.expensesList;
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _displayedExpenses = _allExpenses.where((exp) {
      final query = _searchQuery.toLowerCase();
      return exp.title.toLowerCase().contains(query);
    }).toList();

    _displayedExpenses.sort((a, b) =>
    _isSortAsc ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
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
                  _viewModel.addExpense(newExpense);
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
        Container(
          height: 190,
          color: Colors.transparent,
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
                    onUpdate: (updatedExpense) => _viewModel.updateExpense(updatedExpense),
                    onDelete: (id) => _viewModel.deleteExpense(id),
                  ),
                ),
              );
              _refreshCartBadge();
            },
          ),
        );
      },
    );
  }
}
