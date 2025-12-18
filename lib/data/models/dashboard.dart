class DashboardData {
  final double totalRevenue;
  final double totalExpenses;
  final double totalProfit;
  final double totalCost;
  final int totalSales;
  final int totalProducts;
  final int lowStockProducts;
  final List<MonthlyData> monthlyData;
  final List<YearlyData> yearlyData;

  DashboardData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalProfit,
    required this.totalCost,
    required this.totalSales,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.monthlyData,
    required this.yearlyData,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble() / 100, // Convert from cents
      totalExpenses: (json['total_expenses'] ?? 0).toDouble() / 100,
      totalProfit: (json['total_profit'] ?? 0).toDouble() / 100,
      totalCost: (json['total_cost'] ?? 0).toDouble() / 100,
      totalSales: json['total_sales'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      lowStockProducts: json['low_stock_products'] ?? 0,
      monthlyData: (json['monthly_data'] as List<dynamic>?)
              ?.map((item) => MonthlyData.fromJson(item))
              .toList() ??
          [],
      yearlyData: (json['yearly_data'] as List<dynamic>?)
              ?.map((item) => YearlyData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class MonthlyData {
  final String month;
  final double revenue;
  final double expenses;
  final double profit;
  final int salesCount;

  MonthlyData({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.salesCount,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble() / 100,
      expenses: (json['expenses'] ?? 0).toDouble() / 100,
      profit: (json['profit'] ?? 0).toDouble() / 100,
      salesCount: json['sales_count'] ?? 0,
    );
  }
}

class YearlyData {
  final int year;
  final double revenue;
  final double expenses;
  final double profit;
  final int salesCount;

  YearlyData({
    required this.year,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.salesCount,
  });

  factory YearlyData.fromJson(Map<String, dynamic> json) {
    return YearlyData(
      year: json['year'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble() / 100,
      expenses: (json['expenses'] ?? 0).toDouble() / 100,
      profit: (json['profit'] ?? 0).toDouble() / 100,
      salesCount: json['sales_count'] ?? 0,
    );
  }
}