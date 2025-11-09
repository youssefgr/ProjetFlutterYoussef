import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions%20Crud/subscriptions_detail.dart';
import 'package:projetflutteryoussef/repositories/youssef/subscription_repository.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions%20Crud/subscription_add.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionsList extends StatefulWidget {
  const SubscriptionsList({super.key});

  @override
  State<SubscriptionsList> createState() => _SubscriptionsListState();
}

class _SubscriptionsListState extends State<SubscriptionsList> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  List<UserSubscription> _allSubscriptions = [];
  List<UserSubscription> _displayedSubscriptions = [];
  bool _isLoading = true;
  String _searchQuery = "";
  bool _isSortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  // ✨ LOAD ONLY CURRENT USER'S SUBSCRIPTIONS
  Future<void> _loadSubscriptions() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        print('⚠️ No user logged in');
        return;
      }

      print('👤 Current User: ${currentUser.email}');

      // ✅ Load only current user's subscriptions
      _allSubscriptions = await _repository.getUserSubscriptions();

      print('📊 Loaded ${_allSubscriptions.length} subscriptions for user');

      _applyFilters();
    } catch (e) {
      print('❌ Error loading subscriptions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSortAsc ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: 'Sort by price',
            onPressed: () {
              setState(() => _isSortAsc = !_isSortAsc);
              _applyFilters();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add subscription',
            onPressed: () => _navigateToAdd(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = "");
                    _applyFilters();
                  },
                )
                    : null,
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
        onRefresh: _loadSubscriptions,
        child: _displayedSubscriptions.isEmpty
            ? _buildEmptyState()
            : ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildSubscriptionSection(
              BillingCycle.weekly,
              'Weekly',
              Colors.red,
            ),
            const SizedBox(height: 16),
            _buildSubscriptionSection(
              BillingCycle.monthly,
              'Monthly',
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildSubscriptionSection(
              BillingCycle.yearly,
              'Yearly',
              Colors.green,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(),
        tooltip: 'Add new subscription',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionAdd(),
      ),
    );

    if (result != null) {
      _loadSubscriptions();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No subscriptions found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'Add a subscription to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(),
            icon: const Icon(Icons.add),
            label: const Text('Add subscription'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(
      BillingCycle cycle,
      String title,
      Color color,
      ) {
    final subscriptions = _displayedSubscriptions
        .where((sub) => sub.billingCycle == cycle)
        .toList();

    if (subscriptions.isEmpty) {
      return _buildEmptyCycleSection(title, color);
    }

    double totalCost = subscriptions.fold(0, (sum, sub) => sum + sub.cost);

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
                  '${subscriptions.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Total: €${totalCost.toStringAsFixed(2)}',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: _buildSubscriptionRow(subscriptions, color),
        ),
      ],
    );
  }

  Widget _buildEmptyCycleSection(String title, Color color) {
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
          height: 180,
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
                  'No $title subscriptions',
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

  Widget _buildSubscriptionRow(
      List<UserSubscription> subscriptions,
      Color color,
      ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SizedBox(width: 6),
          ...List.generate(subscriptions.length, (index) {
            final sub = subscriptions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildSubscriptionCard(sub, color),
            );
          }),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(UserSubscription sub, Color color) {
    return SizedBox(
      width: 140,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionDetail(
                  subscription: sub,
                  onDelete: (id) {
                    _loadSubscriptions();
                  },
                ),
              ),
            ).then((_) {
              _loadSubscriptions();
            });
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: color)),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: sub.imageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(sub.imageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: sub.imageUrl.isEmpty
                      ? Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  )
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sub.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '€${sub.cost.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
