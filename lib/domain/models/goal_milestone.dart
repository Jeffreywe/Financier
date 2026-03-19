class GoalMilestone {
  final String id;
  final String goalId;
  final String name;
  final double targetAmount;
  final DateTime? completedAt;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalMilestone({
    required this.id,
    required this.goalId,
    required this.name,
    required this.targetAmount,
    this.completedAt,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  bool get isCompleted => completedAt != null;

  double get percentOfGoal => targetAmount;

  GoalMilestone copyWith({
    String? id,
    String? goalId,
    String? name,
    double? targetAmount,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'name': name,
      'targetAmount': targetAmount,
      'completedAt': completedAt?.toIso8601String(),
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GoalMilestone.fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is GoalMilestone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          name == other.name &&
          targetAmount == other.targetAmount &&
          completedAt == other.completedAt &&
          order == other.order &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      goalId.hashCode ^
      name.hashCode ^
      targetAmount.hashCode ^
      completedAt.hashCode ^
      order.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      '''GoalMilestone(
    id: $id,
    goalId: $goalId,
    name: $name,
    targetAmount: $targetAmount,
    completedAt: $completedAt,
    order: $order,
    createdAt: $createdAt,
    updatedAt: $updatedAt,
  )''';
}
