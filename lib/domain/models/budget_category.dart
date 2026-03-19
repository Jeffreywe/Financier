enum BudgetBucket { needs, wants, savings }

class BudgetCategory {
  final String id;
  final String name;
  final BudgetBucket bucket;
  final bool isDefault;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.bucket,
    this.isDefault = false,
  });

  BudgetCategory copyWith({
    String? id,
    String? name,
    BudgetBucket? bucket,
    bool? isDefault,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      bucket: bucket ?? this.bucket,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bucket': bucket.name,
    'isDefault': isDefault,
  };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    bucket: BudgetBucket.values.byName(json['bucket'] as String),
    isDefault: json['isDefault'] as bool? ?? false,
  );

  String get bucketLabel {
    switch (bucket) {
      case BudgetBucket.needs:
        return 'Needs';
      case BudgetBucket.wants:
        return 'Wants';
      case BudgetBucket.savings:
        return 'Savings';
    }
  }
}

/// Seeded on first launch; user can rename but not delete defaults.
final List<BudgetCategory> defaultBudgetCategories = [
  // Needs — 50%
  BudgetCategory(
    id: 'cat_rent',
    name: 'Rent / Mortgage',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_groceries',
    name: 'Groceries',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_utilities',
    name: 'Utilities',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_insurance',
    name: 'Insurance',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_transport',
    name: 'Transportation',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_medical',
    name: 'Medical',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  // Wants — 30%
  BudgetCategory(
    id: 'cat_dining',
    name: 'Dining Out',
    bucket: BudgetBucket.wants,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_entertainment',
    name: 'Entertainment',
    bucket: BudgetBucket.wants,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_shopping',
    name: 'Shopping',
    bucket: BudgetBucket.wants,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_subscriptions',
    name: 'Subscriptions',
    bucket: BudgetBucket.wants,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_personal',
    name: 'Personal Care',
    bucket: BudgetBucket.wants,
    isDefault: true,
  ),
  // Savings — 20%
  BudgetCategory(
    id: 'cat_savings_transfer',
    name: 'Savings Transfer',
    bucket: BudgetBucket.savings,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_debt_payment',
    name: 'Debt Payment',
    bucket: BudgetBucket.savings,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_investments',
    name: 'Investments',
    bucket: BudgetBucket.savings,
    isDefault: true,
  ),
  // Income
  BudgetCategory(
    id: 'cat_income_paycheck',
    name: 'Paycheck',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
  BudgetCategory(
    id: 'cat_income_other',
    name: 'Other Income',
    bucket: BudgetBucket.needs,
    isDefault: true,
  ),
];
