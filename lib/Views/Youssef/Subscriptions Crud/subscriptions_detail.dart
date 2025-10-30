import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/subscription_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
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
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Subscription',
            onPressed: () {
              Navigator.push<Subscription>(
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubscriptionImage(),
            const SizedBox(height: 24),
            Text(
              subscription.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Cost', '${subscription.cost.toStringAsFixed(2)} €'),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Next Payment Date',
              '${subscription.nextPaymentDate.day}/${subscription.nextPaymentDate.month}/${subscription.nextPaymentDate.year}',
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cycles', subscription.cycles.map((c) => c.name).join(', ')),
            const SizedBox(height: 16),
            _buildInfoRow('User ID', subscription.userId),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionImage() {
    if (subscription.imageURL.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<File?>(
      future: ImageUtils.getImageFile(subscription.imageURL),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              snapshot.data!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          );
        }
        return Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
