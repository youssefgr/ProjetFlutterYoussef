import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:projetflutteryoussef/Views/Youssef/Subscriptions%20Crud/subscriptions_edit.dart';
import 'package:projetflutteryoussef/repositories/subscription_repository.dart';

class SubscriptionDetail extends StatefulWidget {
  final UserSubscription subscription;
  final Function(UserSubscription)? onUpdate;
  final Function(String)? onDelete;

  const SubscriptionDetail({
    super.key,
    required this.subscription,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<SubscriptionDetail> createState() => _SubscriptionDetailState();
}

class _SubscriptionDetailState extends State<SubscriptionDetail> {
  final SubscriptionRepository _repository = SubscriptionRepository();
  bool _isDeleting = false;

  // Calculer les jours avant le prochain paiement
  int get daysUntilNextPayment {
    final now = DateTime.now();
    return widget.subscription.nextBillingDate.difference(now).inDays;
  }

  // Formater la date
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Formater le temps
  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personnalisée avec image de couverture
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.push<UserSubscription>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionEdit(
                        subscription: widget.subscription,
                      ),
                    ),
                  ).then((updatedSubscription) {
                    if (updatedSubscription != null) {
                      widget.onUpdate?.call(updatedSubscription);
                    }
                  });
                },
              ),

              IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
                onPressed: _isDeleting ? null : _deleteSubscription,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.subscription.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: _buildImageHeader(),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix et cycle de facturation
                  _buildPriceCard(),
                  const SizedBox(height: 24),

                  // Informations de paiement
                  _buildPaymentInfo(),
                  const SizedBox(height: 24),

                  // Détails supplémentaires (SANS LES IDS)
                  _buildDetailsSection(),
                  const SizedBox(height: 24),

                  // Notes si présentes
                  if (widget.subscription.notes != null &&
                      widget.subscription.notes!.isNotEmpty)
                    _buildNotesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      color: Colors.grey[300],
      child: widget.subscription.imageUrl.isNotEmpty
          ? Image.network(
        widget.subscription.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.subscriptions,
              size: 100,
              color: Colors.grey[400],
            ),
          );
        },
      )
          : Center(
        child: Icon(
          Icons.image_not_supported,
          size: 100,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '€${widget.subscription.cost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Billing Cycle',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.subscription.billingCycle.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.calendar_today,
          label: 'Start Date',
          value: _formatDate(widget.subscription.startDate),
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.event_note,
          label: 'Next Billing Date',
          value: _formatDate(widget.subscription.nextBillingDate),
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.schedule,
          label: 'Days Until Next Payment',
          value: '${daysUntilNextPayment} days',
          color: daysUntilNextPayment < 7 ? Colors.red : Colors.blue,
        ),
      ],
    );
  }

  // ✅ MÉTHODE MODIFIÉE - SANS LES IDS
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          Chip(
            label: Text(
              widget.subscription.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor:
            widget.subscription.isActive ? Colors.green : Colors.grey,
            avatar: Icon(
              widget.subscription.isActive ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
          ),
          if (widget.subscription.isCustom)
            Chip(
              label: const Text(
                'Custom',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.purple,
              avatar: const Icon(Icons.inbox, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isId = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: isId ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isId)
            IconButton(
              icon: const Icon(Icons.content_copy, size: 18),
              onPressed: () {
                // Copier dans le presse-papiers
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: $value'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.note, color: Colors.amber[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.subscription.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription?'),
        content: Text(
          'Are you sure you want to delete "${widget.subscription.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final success = await _repository.deleteSubscription(
          widget.subscription.id,
        );

        if (mounted) {
          if (success) {
            widget.onDelete?.call(widget.subscription.id);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Subscription deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Failed to delete subscription'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }
}
