import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_view.dart';
import 'package:projetflutteryoussef/viewmodels/subscriptions_viewmodel.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions Crud/subscriptions_add.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions Crud/subscriptions_grid_item.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions Crud/subscriptions_detail.dart';// adapte au bon chemin



class SubscriptionsList extends StatefulWidget {
  const SubscriptionsList({super.key});

  @override
  State<SubscriptionsList> createState() => _SubscriptionsListState();
}

class _SubscriptionsListState extends State<SubscriptionsList> {
  final SubscriptionsViewModel _viewModel = SubscriptionsViewModel();

  bool _isLoading = true;

  void _refreshList() => setState(() {});

  @override
  void initState() {
    super.initState();
    _viewModel.onSubscriptionsUpdated = _onSubscriptionsUpdated;
    _loadSubscriptions();
  }

  void _onSubscriptionsUpdated() {
    setState(() {});
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
    });
    await _viewModel.loadSubscriptions();
    setState(() {
      _isLoading = false;
    });
  }

  bool get _hasItemsInCart => CartManager().hasItems;

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
                MaterialPageRoute(builder: (context) => const SubscriptionsAdd()),
              ).then((newSubscription) {
                if (newSubscription != null) {
                  _viewModel.addSubscription(newSubscription);
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSubscriptionSection(SubscriptionCycle.Weekly, 'Weekly', Colors.red),
              const SizedBox(height: 16),
              _buildSubscriptionSection(SubscriptionCycle.Monthly, 'Monthly', Colors.blue),
              const SizedBox(height: 16),
              _buildSubscriptionSection(SubscriptionCycle.Yearly, 'Yearly', Colors.yellow),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(SubscriptionCycle category, String title, Color color) {
    final sectionSubscriptions = _viewModel.getSubscriptionsByCycle(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$title (${sectionSubscriptions.length})',
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          color: Colors.transparent,
          child: sectionSubscriptions.isEmpty
              ? _buildEmptySection(title, color)
              : _buildSubscriptionGrid(sectionSubscriptions, color),
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
            Text(
              'No subscriptions in $title',
              style: TextStyle(color: color.withOpacity(0.75), fontSize: 16),
            ),
            Text(
              'Add one to get started!',
              style: TextStyle(color: color.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionGrid(List<Subscription> subscriptionsList, Color color) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: subscriptionsList.length,
      itemBuilder: (context, index) {
        final subscription = subscriptionsList[index];
        return Container(
          width: 140,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: SubscriptionsGridItem(
            subscription: subscription,
            sectionColor: color,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionsDetail(
                    subscription: subscription,
                    onUpdate: (updatedSubscription) {
                      _viewModel.updateSubscription(updatedSubscription);
                    },
                    onDelete: (id) {
                      _viewModel.deleteSubscription(id);
                    },
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
