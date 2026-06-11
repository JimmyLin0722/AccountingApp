class MonthlySettings {
  final int? id;
  final String yearMonth; // YYYY-MM
  final int incomeAmount; // 本月固定收入
  final int budgetAmount; // 本月支出預算

  const MonthlySettings({
    this.id,
    required this.yearMonth,
    this.incomeAmount = 0,
    this.budgetAmount = 0,
  });

  factory MonthlySettings.fromMap(Map<String, dynamic> m) => MonthlySettings(
        id: m['setting_id'] as int?,
        yearMonth: m['year_month'] as String,
        incomeAmount: m['income_amount'] as int? ?? 0,
        budgetAmount: m['budget_amount'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'setting_id': id,
        'year_month': yearMonth,
        'income_amount': incomeAmount,
        'budget_amount': budgetAmount,
      };

  MonthlySettings copyWith({int? incomeAmount, int? budgetAmount}) =>
      MonthlySettings(
        id: id,
        yearMonth: yearMonth,
        incomeAmount: incomeAmount ?? this.incomeAmount,
        budgetAmount: budgetAmount ?? this.budgetAmount,
      );
}
