enum AccountType { checking, savings, credit, cash, other }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String? note;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.note,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? note,
    bool clearNote = false,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'balance': balance,
    'note': note,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AccountType.values.byName(json['type'] as String),
    balance: (json['balance'] as num).toDouble(),
    note: json['note'] as String?,
  );

  String get typeLabel {
    switch (type) {
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'Savings';
      case AccountType.credit:
        return 'Credit';
      case AccountType.cash:
        return 'Cash';
      case AccountType.other:
        return 'Other';
    }
  }
}
