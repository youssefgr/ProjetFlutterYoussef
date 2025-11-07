import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';

class ExpensesGridItem extends StatelessWidget {
  final Expenses expense;
  final Color sectionColor;
  final VoidCallback onTap;

  const ExpensesGridItem({
    super.key,
    required this.expense,
    required this.sectionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = expense.amount <= 0;

    return SizedBox(
      width: 140,
      child: GestureDetector(
        onTap: isOutOfStock ? null : onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Image
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (expense.imageURL.isNotEmpty)
                              Image.network(
                                expense.imageURL,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: sectionColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: sectionColor.withOpacity(0.5),
                                      size: 40,
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                color: sectionColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: sectionColor.withOpacity(0.5),
                                  size: 40,
                                ),
                              ),
                            // Badge catégorie
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: sectionColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  expense.category.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // ✨ BADGE OUT OF STOCK
                            if (isOutOfStock)
                              Container(
                                color: Colors.black.withOpacity(0.6),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.block,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'OUT OF STOCK',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Infos
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          color: isOutOfStock
                              ? Colors.grey.shade100
                              : Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              expense.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isOutOfStock
                                    ? Colors.grey.shade500
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '€${expense.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isOutOfStock
                                        ? Colors.grey.shade400
                                        : sectionColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                // ✨ AFFICHAGE QUANTITÉ
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red.shade100
                                        : sectionColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isOutOfStock
                                        ? '0 left'
                                        : '${expense.amount.toInt()} left',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock
                                          ? Colors.red
                                          : sectionColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ✨ COUCHE DÉSACTIVATION SI OUT OF STOCK
                if (isOutOfStock)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
