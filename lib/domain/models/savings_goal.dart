enum GoalStatus { active, paused, completed }

enum ContributionFrequency {
  none,
  weekly,
  biweekly,
  monthly,
  quarterly,
  annually,
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? linkedAccountId;
  final DateTime startDate;
  final DateTime dueDate;
  final GoalStatus status;
  final bool isRecurringContribution;
  final double? recurringAmount;
  final ContributionFrequency recurringFrequency;
  final bool autoGenerateTransaction;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.linkedAccountId,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.isRecurringContribution,
    this.recurringAmount,
    required this.recurringFrequency,
    required this.autoGenerateTransaction,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  double get percentComplete {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  int get daysSinceStart {
    return DateTime.now().difference(startDate).inDays;
  }

  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status != GoalStatus.completed;
  }

  bool get isCompleted {
    return currentAmount >= targetAmount || status == GoalStatus.completed;
  }

  String get statusLabel {
    switch (status) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.completed:
        return 'Completed';
    }
  }

  String get frequencyLabel {
    switch (recurringFrequency) {
      case ContributionFrequency.none:
        return 'None';
      case ContributionFrequency.weekly:
        return 'Weekly';
      case ContributionFrequency.biweekly:
        return 'Biweekly';
      case ContributionFrequency.monthly:
        return 'Monthly';
      case ContributionFrequency.quarterly:
        return 'Quarterly';
      case ContributionFrequency.annually:
        return 'Annually';
    }
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? linkedAccountId,
    DateTime? startDate,
    DateTime? dueDate,
    GoalStatus? status,
    bool? isRecurringContribution,
    double? recurringAmount,
    ContributionFrequency? recurringFrequency,
    bool? autoGenerateTransaction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      isRecurringContribution:
          isRecurringContribution ?? this.isRecurringContribution,
      recurringAmount: recurringAmount ?? this.recurringAmount,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      autoGenerateTransaction:
          autoGenerateTransaction ?? this.autoGenerateTransaction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'linkedAccountId': linkedAccountId,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'isRecurringContribution': isRecurringContribution,
      'recurringAmount': recurringAmount,
      'recurringFrequency': recurringFrequency.name,
      'autoGenerateTransaction': autoGenerateTransaction,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      linkedAccountId: json['linkedAccountId'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: GoalStatus.values.byName(json['status'] as String? ?? 'active'),
      isRecurringContribution:
          json['isRecurringContribution'] as bool? ?? false,
      recurringAmount: json['recurringAmount'] != null
          ? (json['recurringAmount'] as num).toDouble()
          : null,
      recurringFrequency: ContributionFrequency.values.byName(
        json['recurringFrequency'] as String? ?? 'none',
      ),
      autoGenerateTransaction:
          json['autoGenerateTransaction'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is SavingsGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          linkedAccountId == other.linkedAccountId &&
          startDate == other.startDate &&
          dueDate == other.dueDate &&
          status == other.status &&
          isRecurringContribution == other.isRecurringContribution &&
          recurringAmount == other.recurringAmount &&
          recurringFrequency == other.recurringFrequency &&
          autoGenerateTransaction == other.autoGenerateTransaction &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      targetAmount.hashCode ^
      currentAmount.hashCode ^
      linkedAccountId.hashCode ^
      startDate.hashCode ^
      dueDate.hashCode ^
      status.hashCode ^
      isRecurringContribution.hashCode ^
      recurringAmount.hashCode ^
      recurringFrequency.hashCode ^
      autoGenerateTransaction.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      '''SavingsGoal(
    id: $id,
    name: $name,
    targetAmount: $targetAmount,
    currentAmount: $currentAmount,
    linkedAccountId: $linkedAccountId,
    startDate: $startDate,
    dueDate: $dueDate,
    status: $status,
    isRecurringContribution: $isRecurringContribution,
    recurringAmount: $recurringAmount,
    recurringFrequency: $recurringFrequency,
    autoGenerateTransaction: $autoGenerateTransaction,
    createdAt: $createdAt,
    updatedAt: $updatedAt,
  )''';
}
