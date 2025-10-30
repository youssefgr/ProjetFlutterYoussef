import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_view.dart';
import 'package:projetflutteryoussef/viewmodels/subscriptions_viewmodel.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions Crud/subscriptions_add.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions Crud/subscriptions_grid_item.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions Crud/subscriptions_detail.dart';

class SubscriptionsList extends StatefulWidget {
  const SubscriptionsList({super.key});

  @override
  State<SubscriptionsList> createState() => _SubscriptionsListState();
}
class _SubscriptionsListState extends State<SubscriptionsList> {
  final SubscriptionsViewModel _viewModel = SubscriptionsViewModel();

  List<Subscription> _allSubscriptions = [];
  List<Subscription> _displayedSubscriptions = [];

  bool _isLoading = true;
  String _searchQuery = "";
  bool _isSortAsc = true;

  void _refreshList() {
    setState(() {});
  }

  bool get _hasItemsInCart => CartManager().hasItems;

  @override
  void initState() {
    super.initState();
    _viewModel.onSubscriptionsUpdated = _onSubscriptionsUpdated;
    _loadSubscriptions();
  }

  void _onSubscriptionsUpdated() {
    _allSubscriptions = _viewModel.subscriptionsList;
    _applyFilters();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    await _viewModel.loadSubscriptions();
    _allSubscriptions = _viewModel.subscriptionsList;
    _applyFilters();
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    _displayedSubscriptions = _allSubscriptions.where((sub) {
      final query = _searchQuery.toLowerCase();
      return sub.name.toLowerCase().contains(query);
    }).toList();

    _displayedSubscriptions.sort((a, b) =>
    _isSortAsc ? a.cost.compareTo(b.cost) : b.cost.compareTo(a.cost));

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
        title: const Text('My Subscriptions'),
        actions: [
          IconButton(
            icon: Icon(
                _isSortAsc ? Icons.arrow_downward : Icons.arrow_upward),
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
                tooltip: 'View Cart',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartView()),
                  );
                  _refreshList();
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
            tooltip: 'Add Subscription',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionsAdd()),
              ).then((newSubscription) {
                if (newSubscription != null) {
                  _viewModel.addSubscription(newSubscription);
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
                    borderRadius: BorderRadius.circular(8)),
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
        onRefresh: _loadSubscriptions,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildSubscriptionSection(
                SubscriptionCycle.Weekly, 'Weekly', Colors.red),
            const SizedBox(height: 16),
            _buildSubscriptionSection(
                SubscriptionCycle.Monthly, 'Monthly', Colors.blue),
            const SizedBox(height: 16),
            _buildSubscriptionSection(
                SubscriptionCycle.Yearly, 'Yearly', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(
      SubscriptionCycle cycle, String title, Color color) {
    final subscriptions =
    _displayedSubscriptions.where((sub) => sub.cycles.contains(cycle)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: subscriptions.isEmpty
              ? _buildEmptySection(title, color)
              : _buildSubscriptionGrid(subscriptions, color),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 45, color: color.withOpacity(0.5)),
            const SizedBox(height: 6),
            Text('${title} [translate:n’a pas d’abonnements]',
                style: TextStyle(color: color.withOpacity(0.75), fontSize: 16)),
            Text('[translate:Ajoute-en un pour commencer !]',
                style: TextStyle(color: color.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionGrid(List<Subscription> subscriptions, Color color) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        return Container(
          width: 140,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: SubscriptionsGridItem(
            subscription: sub,
            sectionColor: color,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionsDetail(
                    subscription: sub,
                    onUpdate: (updated) => _viewModel.updateSubscription(updated),
                    onDelete: (id) => _viewModel.deleteSubscription(id),
                  ),
                ),
              );
              _refreshList();
            },
          ),
        );
      },
    );
  }
}
