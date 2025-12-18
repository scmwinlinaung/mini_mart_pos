// Expense-related models based on database schema

class ExpenseCategory {
  final int categoryId;
  final String categoryName;

  ExpenseCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId;

  @override
  int get hashCode => categoryId.hashCode;

  @override
  String toString() {
    return 'ExpenseCategory{categoryId: $categoryId, categoryName: $categoryName}';
  }
}

class Expense {
  final int expenseId;
  final int categoryId;
  final String? categoryName;
  final int userId;
  final String? userName;
  final String title;
  final String? description;
  final int amount; // in cents
  final DateTime expenseDate;
  final DateTime createdAt;

  Expense({
    required this.expenseId,
    required this.categoryId,
    this.categoryName,
    required this.userId,
    this.userName,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      expenseId: map['expense_id'] as int,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String?,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: map['amount'] as int,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expense_id': expenseId,
      'category_id': categoryId,
      'category_name': categoryName,
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  double get amountDouble => amount / 100.0;
  String get formattedAmount => '\$${(amount / 100).toStringAsFixed(2)}';
  String get categoryDisplay => categoryName ?? 'Unknown Category';
  String get expenseDateDisplay => '${expenseDate.day}/${expenseDate.month}/${expenseDate.year}';
  String get createdAtDisplay => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  bool get isTodayExpense {
    final now = DateTime.now();
    return expenseDate.year == now.year &&
        expenseDate.month == now.month &&
        expenseDate.day == now.day;
  }

  bool get isThisMonthExpense {
    final now = DateTime.now();
    return expenseDate.year == now.year &&
        expenseDate.month == now.month;
  }

  bool get isThisYearExpense {
    final now = DateTime.now();
    return expenseDate.year == now.year;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          expenseId == other.expenseId;

  @override
  int get hashCode => expenseId.hashCode;

  @override
  String toString() {
    return 'Expense{expenseId: $expenseId, title: $title, amount: $formattedAmount, category: $categoryDisplay}';
  }
}

class ExpenseWithCategory {
  final Expense expense;
  final ExpenseCategory category;

  ExpenseWithCategory({
    required this.expense,
    required this.category,
  });

  String get categoryName => category.categoryName;
  int get categoryId => category.categoryId;

  @override
  String toString() {
    return 'ExpenseWithCategory{expense: $expense, category: $category}';
  }
}

class ExpenseSummary {
  final DateTime period;
  final int totalExpenses; // in cents
  final int expenseCount;
  final Map<String, int> expensesByCategory; // category name -> amount
  final List<Expense> recentExpenses;

  ExpenseSummary({
    required this.period,
    required this.totalExpenses,
    required this.expenseCount,
    required this.expensesByCategory,
    required this.recentExpenses,
  });

  // Helper getters for UI
  double get totalExpensesDouble => totalExpenses / 100.0;
  String get formattedTotalExpenses => '\$${(totalExpenses / 100).toStringAsFixed(2)}';
  String get periodDisplay => '${period.month}/${period.year}';

  String? get topCategory {
    if (expensesByCategory.isEmpty) return null;
    var maxAmount = 0;
    String? topCategoryName;

    expensesByCategory.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategoryName = category;
      }
    });

    return topCategoryName;
  }

  double get topCategoryAmount {
    if (expensesByCategory.isEmpty) return 0.0;
    var maxAmount = 0;

    expensesByCategory.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
      }
    });

    return maxAmount / 100.0;
  }

  @override
  String toString() {
    return 'ExpenseSummary{period: $periodDisplay, total: $formattedTotalExpenses, count: $expenseCount}';
  }
}