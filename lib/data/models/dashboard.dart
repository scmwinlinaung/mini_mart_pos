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
    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DashboardData(
      totalRevenue: toDouble(json['total_revenue']),
      totalExpenses: toDouble(json['total_expenses']),
      totalProfit: toDouble(json['total_profit']),
      totalCost: toDouble(json['total_cost']),
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
    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MonthlyData(
      month: json['month'] ?? '',
      revenue: toDouble(json['revenue']),
      expenses: toDouble(json['expenses']),
      profit: toDouble(json['profit']),
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
    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return YearlyData(
      year: json['year'] ?? 0,
      revenue: toDouble(json['revenue']),
      expenses: toDouble(json['expenses']),
      profit: toDouble(json['profit']),
      salesCount: json['sales_count'] ?? 0,
    );
  }
}