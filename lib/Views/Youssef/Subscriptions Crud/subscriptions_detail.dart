import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'subscriptions_delete.dart';
import 'subscriptions_edit.dart';

class SubscriptionsDetail extends StatelessWidget {
  final Subscription subscription;
  final Function(Subscription)? onUpdate;
  final Function(String)? onDelete;

  const SubscriptionsDetail({
    super.key,
    required this.subscription,
    this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.name),
        actions: [
          // Modifier l'abonnement
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Subscription',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionsEdit(subscription: subscription),
                ),
              ).then((updatedSubscription) {
                if (updatedSubscription != null) {
                  onUpdate?.call(updatedSubscription);
                  Navigator.pop(context, updatedSubscription);
                }
              });
            },
          ),
          // Supprimer l'abonnement
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Subscription',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SubscriptionsDelete(
                  subscription: subscription,
                  onDelete: () {
                    onDelete?.call(subscription.id);
                  },
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subscription.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cost', '${subscription.cost.toStringAsFixed(2)} €'),
            const SizedBox(height: 16),
            _buildInfoRow('Next Payment Date',
                '${subscription.nextPaymentDate.day}/${subscription.nextPaymentDate.month}/${subscription.nextPaymentDate.year}'),
            const SizedBox(height: 16),
            _buildInfoRow('Cycles', subscription.cycles.map((c) => c.name).join(', ')),
            const SizedBox(height: 16),
            _buildInfoRow('User ID', subscription.userId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            )),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
