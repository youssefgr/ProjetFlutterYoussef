import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/viewmodels/expenses_viewmodel.dart';
import 'expenses_add.dart';
import 'expenses_detail.dart';
import '../expenses_grid_item.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({super.key});

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  final ExpensesViewModel _viewModel = ExpensesViewModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewModel.onExpensesUpdated = _onExpensesUpdated;
    _loadExpenses();
  }

  void _onExpensesUpdated() {
    setState(() {});
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });
    await _viewModel.loadExpenses();
    setState(() {
      _isLoading = false;
    });
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
        title: const Text('My Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Expense',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpensesAdd()),
              ).then((newExpense) {
                if (newExpense != null) {
                  _viewModel.addExpense(newExpense);
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildExpenseSection(ExpensesCategory.Manga, 'Manga', Colors.red),
              const SizedBox(height: 16),
              _buildExpenseSection(ExpensesCategory.Merchandise, 'Merchandise', Colors.blue),
              const SizedBox(height: 16),
              _buildExpenseSection(ExpensesCategory.EventTicket, 'Event Tickets', Colors.yellow),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseSection(ExpensesCategory category, String title, Color color) {
    final sectionExpenses = _viewModel.getExpensesByCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
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

        // Section content (scrollable cards)
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
              'No expenses in $title',
              style: TextStyle(
                color: color.withOpacity(0.75),
                fontSize: 16,
              ),
            ),
            Text(
              'Add one to get started!',
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: expensesList.length,
      itemBuilder: (context, index) {
        final expense = expensesList[index];

        return Container(
          width: 130,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: ExpensesGridItem(
            expense: expense,
            sectionColor: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesDetail(
                    expense: expense,
                    onUpdate: (updatedExpense) {
                      _viewModel.updateExpense(updatedExpense);
                    },
                    onDelete: (id) {
                      _viewModel.deleteExpense(id);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
