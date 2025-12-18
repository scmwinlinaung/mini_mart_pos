import 'package:mini_mart_pos/data/models/product.dart';
import 'package:mini_mart_pos/data/models/dashboard.dart';
import 'package:postgres/postgres.dart';
import 'package:mini_mart_pos/core/services/database_service.dart';

class PosRepository {
  final DatabaseService _dbService;

  PosRepository(this._dbService);

  // Find product by barcode
  Future<Product?> getProduct(String barcode) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM products WHERE barcode = @barcode'),
      parameters: {'barcode': barcode},
    );

    if (result.isEmpty) return null;
    return Product.fromMap(result.first.toColumnMap());
  }

  // Execute Sale Transaction
  Future<void> submitSale(List<CartItem> items, int total, int userId) async {
    final conn = await _dbService.connection;

    await conn.runTx((ctx) async {
      final invoice = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Insert Header
      final saleRes = await ctx.execute(
        Sql.named('''
          INSERT INTO sales (invoice_no, user_id, sub_total, grand_total, payment_method)
          VALUES (@inv, @uid, @tot, @tot, 'CASH') RETURNING sale_id
        '''),
        parameters: {'inv': invoice, 'uid': userId, 'tot': total},
      );
      final saleId = saleRes.first[0] as int;

      // 2. Insert Items (Trigger handles stock deduction)
      for (var item in items) {
        await ctx.execute(
          Sql.named('''
            INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, total_price)
            VALUES (@sid, @pid, @qty, @price, @total)
          '''),
          parameters: {
            'sid': saleId,
            'pid': item.product.productId,
            'qty': item.quantity,
            'price': item.product.sellPrice,
            'total': item.total,
          },
        );
      }
    });
  }

  // Dashboard Data Methods
  Future<DashboardData> getDashboardData() async {
    final conn = await _dbService.connection;

    // Get summary data
    final summaryResult = await conn.execute('''
      SELECT
        COALESCE(SUM(s.grand_total), 0) as total_revenue,
        COALESCE(SUM(si.total_price * si.quantity), 0) as total_cost,
        (SELECT COALESCE(SUM(amount), 0) FROM expenses) as total_expenses,
        COUNT(DISTINCT s.sale_id) as total_sales,
        (SELECT COUNT(*) FROM products WHERE is_active = true) as total_products,
        (SELECT COUNT(*) FROM products WHERE stock_quantity <= reorder_level AND is_active = true) as low_stock_products
      FROM sales s
      LEFT JOIN sale_items si ON s.sale_id = si.sale_id
      WHERE s.created_at >= DATE_TRUNC('year', CURRENT_DATE)
    ''');

    // Get monthly data for the current year
    final monthlyResult = await conn.execute('''
      SELECT
        TO_CHAR(DATE_TRUNC('month', created_at), 'Mon') as month,
        EXTRACT(MONTH FROM created_at) as month_num,
        COALESCE(SUM(grand_total), 0) as revenue,
        0 as expenses,
        COALESCE(SUM(grand_total), 0) as profit,
        COUNT(sale_id) as sales_count
      FROM sales
      WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE)
      GROUP BY DATE_TRUNC('month', created_at), TO_CHAR(DATE_TRUNC('month', created_at), 'Mon'), EXTRACT(MONTH FROM created_at)
      ORDER BY month_num
    ''');

    // Get yearly data for the last 5 years
    final yearlyResult = await conn.execute('''
      SELECT
        EXTRACT(YEAR FROM created_at) as year,
        COALESCE(SUM(grand_total), 0) as revenue,
        0 as expenses,
        COALESCE(SUM(grand_total), 0) as profit,
        COUNT(sale_id) as sales_count
      FROM sales
      WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE - INTERVAL '5 years')
      GROUP BY EXTRACT(YEAR FROM created_at)
      ORDER BY year
    ''');

    // Get monthly expenses
    final monthlyExpensesResult = await conn.execute('''
      SELECT
        TO_CHAR(DATE_TRUNC('month', created_at), 'Mon') as month,
        EXTRACT(MONTH FROM created_at) as month_num,
        COALESCE(SUM(amount), 0) as expenses
      FROM expenses
      WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE)
      GROUP BY DATE_TRUNC('month', created_at), TO_CHAR(DATE_TRUNC('month', created_at), 'Mon'), EXTRACT(MONTH FROM created_at)
      ORDER BY month_num
    ''');

    // Get yearly expenses
    final yearlyExpensesResult = await conn.execute('''
      SELECT
        EXTRACT(YEAR FROM created_at) as year,
        COALESCE(SUM(amount), 0) as expenses
      FROM expenses
      WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE - INTERVAL '5 years')
      GROUP BY EXTRACT(YEAR FROM created_at)
      ORDER BY year
    ''');

    final summary = summaryResult.first.toColumnMap();
    final totalRevenue = (summary['total_revenue'] ?? 0) as int;
    final totalCost = (summary['total_cost'] ?? 0) as int;
    final totalExpenses = (summary['total_expenses'] ?? 0) as int;
    final totalProfit = totalRevenue - totalCost - totalExpenses;

    // Combine monthly revenue and expenses data
    final List<MonthlyData> monthlyData = [];
    for (int i = 1; i <= 12; i++) {
      final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][i - 1];

      ResultRow? monthRevenue;
      try {
        monthRevenue = monthlyResult.firstWhere(
          (row) => (row[1] as double).toInt() == i,
        );
      } catch (e) {
        monthRevenue = null;
      }

      ResultRow? monthExpense;
      try {
        monthExpense = monthlyExpensesResult.firstWhere(
          (row) => (row[1] as double).toInt() == i,
        );
      } catch (e) {
        monthExpense = null;
      }

      final revenue = (monthRevenue?[2] ?? 0) as int;
      final expenses = (monthExpense?[2] ?? 0) as int;
      final profit = revenue - expenses;

      monthlyData.add(MonthlyData(
        month: monthName,
        revenue: revenue.toDouble() / 100,
        expenses: expenses.toDouble() / 100,
        profit: profit.toDouble() / 100,
        salesCount: (monthRevenue?[5] ?? 0) as int,
      ));
    }

    // Combine yearly revenue and expenses data
    final List<YearlyData> yearlyData = [];
    for (final row in yearlyResult) {
      final year = (row[0] as double).toInt();
      final revenue = (row[1] as int);

      ResultRow? expenseRow;
      try {
        expenseRow = yearlyExpensesResult.firstWhere(
          (expRow) => (expRow[0] as double).toInt() == year,
        );
      } catch (e) {
        expenseRow = null;
      }

      final expenses = (expenseRow?[1] ?? 0) as int;
      final profit = revenue - expenses;

      yearlyData.add(YearlyData(
        year: year,
        revenue: revenue.toDouble() / 100,
        expenses: expenses.toDouble() / 100,
        profit: profit.toDouble() / 100,
        salesCount: (row[4] ?? 0) as int,
      ));
    }

    return DashboardData(
      totalRevenue: totalRevenue.toDouble() / 100,
      totalExpenses: totalExpenses.toDouble() / 100,
      totalProfit: totalProfit.toDouble() / 100,
      totalCost: totalCost.toDouble() / 100,
      totalSales: (summary['total_sales'] ?? 0) as int,
      totalProducts: (summary['total_products'] ?? 0) as int,
      lowStockProducts: (summary['low_stock_products'] ?? 0) as int,
      monthlyData: monthlyData,
      yearlyData: yearlyData,
    );
  }
}
