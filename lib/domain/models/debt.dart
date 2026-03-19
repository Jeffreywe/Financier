enum DebtType {
  creditCard,
  studentLoan,
  carLoan,
  mortgage,
  personalLoan,
  medicalDebt,
  other,
}

extension DebtTypeLabel on DebtType {
  String get debtTypeLabel {
    switch (this) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.studentLoan:
        return 'Student Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.mortgage:
        return 'Mortgage';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.medicalDebt:
        return 'Medical Debt';
      case DebtType.other:
        return 'Other';
    }
  }
}

class Debt {
  final String id;
  final String name;
  final DebtType debtType;
  final double balance;
  final double? interestRate;
  final double? minimumPayment;
  final double? customPayment;
  final int? dueDay; // day of month (1-31)
  final String? note;

  const Debt({
    required this.id,
    required this.name,
    required this.debtType,
    required this.balance,
    this.interestRate,
    this.minimumPayment,
    this.customPayment,
    this.dueDay,
    this.note,
  });

  Debt copyWith({
    String? id,
    String? name,
    DebtType? debtType,
    double? balance,
    double? interestRate,
    double? minimumPayment,
    double? customPayment,
    int? dueDay,
    String? note,
    bool clearInterestRate = false,
    bool clearMinimumPayment = false,
    bool clearCustomPayment = false,
    bool clearDueDay = false,
    bool clearNote = false,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      debtType: debtType ?? this.debtType,
      balance: balance ?? this.balance,
      interestRate: clearInterestRate
          ? null
          : (interestRate ?? this.interestRate),
      minimumPayment: clearMinimumPayment
          ? null
          : (minimumPayment ?? this.minimumPayment),
      customPayment: clearCustomPayment
          ? null
          : (customPayment ?? this.customPayment),
      dueDay: clearDueDay ? null : (dueDay ?? this.dueDay),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'debtType': debtType.name,
    'balance': balance,
    'interestRate': interestRate,
    'minimumPayment': minimumPayment,
    'customPayment': customPayment,
    'dueDay': dueDay,
    'note': note,
  };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'] as String,
    name: json['name'] as String,
    debtType: DebtType.values.byName(json['debtType'] as String),
    balance: (json['balance'] as num).toDouble(),
    interestRate: (json['interestRate'] as num?)?.toDouble(),
    minimumPayment: (json['minimumPayment'] as num?)?.toDouble(),
    customPayment: (json['customPayment'] as num?)?.toDouble(),
    dueDay: json['dueDay'] as int?,
    note: json['note'] as String?,
  );

  String get debtTypeLabel {
    switch (debtType) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.studentLoan:
        return 'Student Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.mortgage:
        return 'Mortgage';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.medicalDebt:
        return 'Medical Debt';
      case DebtType.other:
        return 'Other';
    }
  }
}
