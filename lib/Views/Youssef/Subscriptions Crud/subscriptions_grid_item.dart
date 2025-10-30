import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';

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
        width: 130,
        height: 130,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _truncateTitle(subscription.name, 20),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Cost: ${subscription.cost.toStringAsFixed(2)} €',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: sectionColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cycles:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: sectionColor,
                fontSize: 12,
              ),
            ),
            Text(
              subscription.cycles.map((c) => c.name).join(', '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _truncateTitle(String title, int maxLength) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }
}
