import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';

class SubscriptionsGridItem extends StatelessWidget {
  final Subscription subscription;
  final Color sectionColor;
  final VoidCallback onTap;

  const SubscriptionsGridItem({
    super.key,
    required this.subscription,
    required this.sectionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 150,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: sectionColor.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubscriptionImage(),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                _truncateTitle(subscription.name, 20),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ' ${subscription.cost.toStringAsFixed(2)} €',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sectionColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${subscription.nextPaymentDate.day}/${subscription.nextPaymentDate.month}/${subscription.nextPaymentDate.year}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: sectionColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionImage() {
    if (subscription.imageURL.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
      );
    }

    return FutureBuilder<File?>(
      future: ImageUtils.getImageFile(subscription.imageURL),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 80,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: CircularProgressIndicator(color: sectionColor),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Image.file(
              snapshot.data!,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        }
        return Container(
          height: 80,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
        );
      },
    );
  }

  String _truncateTitle(String title, [int maxLength = 20]) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }
}
