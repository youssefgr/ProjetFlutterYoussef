class UserSubscription {
  final String id;
  final String userId;
  final String name;
  final String imageUrl;
  final double cost;
  final BillingCycle billingCycle;
  final DateTime startDate;
  final DateTime nextBillingDate;
  final bool isActive;
  final String? notes;
  final bool isCustom;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.cost,
    required this.billingCycle,
    required this.startDate,
    required this.nextBillingDate,
    this.isActive = true,
    this.notes,
    this.isCustom = false,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      cost: (json['cost'] as num).toDouble(),
      billingCycle: BillingCycle.values.firstWhere(
            (e) => e.name == json['billing_cycle'],
        orElse: () => BillingCycle.monthly,
      ),
      startDate: DateTime.parse(json['start_date']),
      nextBillingDate: DateTime.parse(json['next_billing_date']),
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      isCustom: json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'image_url': imageUrl,
      'cost': cost,
      'billing_cycle': billingCycle.name,
      'start_date': startDate.toIso8601String(),
      'next_billing_date': nextBillingDate.toIso8601String(),
      'is_active': isActive,
      'notes': notes,
      'is_custom': isCustom,
    };
  }

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    double? cost,
    BillingCycle? billingCycle,
    DateTime? startDate,
    DateTime? nextBillingDate,
    bool? isActive,
    String? notes,
    bool? isCustom,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      cost: cost ?? this.cost,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

enum BillingCycle {
  weekly,
  monthly,
  yearly,
}

extension BillingCycleExtension on BillingCycle {
  String get displayName {
    switch (this) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }

  DateTime calculateNextBillingDate(DateTime startDate) {
    switch (this) {
      case BillingCycle.weekly:
        return startDate.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(
          startDate.year,
          startDate.month + 1,
          startDate.day,
        );
      case BillingCycle.yearly:
        return DateTime(
          startDate.year + 1,
          startDate.month,
          startDate.day,
        );
    }
  }
}