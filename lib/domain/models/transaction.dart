enum TransactionType { income, expense, note }

enum RecurrenceFrequency {
  none,
  weekly,
  biweekly,
  monthly,
  quarterly,
  annually,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final bool isRecurring;
  final RecurrenceFrequency recurrenceFrequency;
  final String? accountId;
  final String? debtId;
  final String? note;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.isRecurring = false,
    this.recurrenceFrequency = RecurrenceFrequency.none,
    this.accountId,
    this.debtId,
    this.note,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    bool? isRecurring,
    RecurrenceFrequency? recurrenceFrequency,
    String? accountId,
    String? debtId,
    String? note,
    bool clearNote = false,
    bool clearAccountId = false,
    bool clearDebtId = false,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      debtId: clearDebtId ? null : (debtId ?? this.debtId),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.name,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'isRecurring': isRecurring,
    'recurrenceFrequency': recurrenceFrequency.name,
    'accountId': accountId,
    'debtId': debtId,
    'note': note,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String? ?? 'expense';
    final parsedType = TransactionType.values.firstWhere(
      (v) => v.name == typeRaw,
      orElse: () => TransactionType.expense,
    );

    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: parsedType,
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceFrequency: RecurrenceFrequency.values.byName(
        json['recurrenceFrequency'] as String? ?? 'none',
      ),
      accountId: json['accountId'] as String?,
      debtId: json['debtId'] as String?,
      note: json['note'] as String?,
    );
  }

  String get recurrenceLabel {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.none:
        return 'One-time';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Biweekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.annually:
        return 'Annually';
    }
  }

  /// Computes the next occurrence date after [from] for recurring transactions.
  DateTime? nextOccurrenceAfter(DateTime from) {
    if (!isRecurring || recurrenceFrequency == RecurrenceFrequency.none) {
      return null;
    }
    DateTime next = date;
    while (!next.isAfter(from)) {
      switch (recurrenceFrequency) {
        case RecurrenceFrequency.weekly:
          next = next.add(const Duration(days: 7));
        case RecurrenceFrequency.biweekly:
          next = next.add(const Duration(days: 14));
        case RecurrenceFrequency.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
        case RecurrenceFrequency.quarterly:
          next = DateTime(next.year, next.month + 3, next.day);
        case RecurrenceFrequency.annually:
          next = DateTime(next.year + 1, next.month, next.day);
        case RecurrenceFrequency.none:
          return null;
      }
    }
    return next;
  }
}
