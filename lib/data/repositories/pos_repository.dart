import 'package:mini_mart_pos/data/models/product.dart';
import 'package:mini_mart_pos/data/models/dashboard.dart';
import 'package:mini_mart_pos/data/models/sales.dart';
import 'package:postgres/postgres.dart';
import 'package:mini_mart_pos/core/services/database_service.dart';
import 'package:mini_mart_pos/core/services/invoice_service.dart';

class PosRepository {
  final DatabaseService _dbService;
  late final InvoiceService _invoiceService;

  PosRepository(this._dbService) {
    _invoiceService = InvoiceService(_dbService);
  }

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
  Future<void> submitSale(
    List<CartItem> items,
    double total,
    int userId,
  ) async {
    final conn = await _dbService.connection;

    // Generate sequential invoice number
    final invoice = await _invoiceService.generateNextInvoiceNumber();

    await conn.runTx((ctx) async {
      // Insert each cart item as a separate row in the sales table
      // (Schema stores line items directly, not a header-items pattern)
      for (var item in items) {
        await ctx.execute(
          Sql.named('''
            INSERT INTO sales (
              invoice_no, user_id, product_id, unit_type_id, barcode, product_name,
              quantity, unit_price, total_price, tax_amount, discount_amount,
              sub_total, grand_total, payment_method, payment_status
            )
            VALUES (
              @inv, @uid, @pid, @utid, @barcode, @pname,
              @qty, @uprice, @tprice, 0, 0,
              @tprice, @tprice, 'CASH', 'PAID'
            )
          '''),
          parameters: {
            'inv': invoice,
            'uid': userId,
            'pid': item.product.productId,
            'utid': item.product.unitTypeId,
            'barcode': item.product.barcode,
            'pname': item.product.productName,
            'qty': item.quantity,
            'uprice': item.unitPrice,
            'tprice': item.total,
          },
        );
      }
    });
  }

  // Dashboard Data Methods
  Future<DashboardData> getDashboardData() async {
    final conn = await _dbService.connection;

    // Helper function to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Get summary data
    final summaryResult = await conn.execute('''
      SELECT
        COALESCE(SUM(s.grand_total), 0) as total_revenue,
        COALESCE(SUM(p.cost_price * s.quantity), 0) as total_cost,
        (SELECT COALESCE(SUM(amount), 0) FROM expenses) as total_expenses,
        COUNT(DISTINCT s.invoice_no) as total_sales,
        (SELECT COUNT(*) FROM products WHERE is_active = true) as total_products,
        (SELECT COUNT(*) FROM products WHERE stock_quantity <= reorder_level AND is_active = true) as low_stock_products
      FROM sales s
      LEFT JOIN products p ON s.product_id = p.product_id
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
        COUNT(DISTINCT invoice_no) as sales_count
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
        COUNT(DISTINCT invoice_no) as sales_count
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
    final totalRevenue = toInt(summary['total_revenue']);
    final totalCost = toInt(summary['total_cost']);
    final totalExpenses = toInt(summary['total_expenses']);
    final totalProfit = totalRevenue - totalCost - totalExpenses;

    // Combine monthly revenue and expenses data
    final List<MonthlyData> monthlyData = [];
    for (int i = 1; i <= 12; i++) {
      final monthName = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][i - 1];

      ResultRow? monthRevenue;
      try {
        monthRevenue = monthlyResult.firstWhere(
          (row) => toDouble(row[1]).toInt() == i,
        );
      } catch (e) {
        monthRevenue = null;
      }

      ResultRow? monthExpense;
      try {
        monthExpense = monthlyExpensesResult.firstWhere(
          (row) => toDouble(row[1]).toInt() == i,
        );
      } catch (e) {
        monthExpense = null;
      }

      final revenue = toInt(monthRevenue?[2]);
      final expenses = toInt(monthExpense?[2]);
      final profit = revenue - expenses;

      monthlyData.add(
        MonthlyData(
          month: monthName,
          revenue: revenue.toDouble() / 100,
          expenses: expenses.toDouble() / 100,
          profit: profit.toDouble() / 100,
          salesCount: toInt(monthRevenue?[5]),
        ),
      );
    }

    // Combine yearly revenue and expenses data
    final List<YearlyData> yearlyData = [];
    for (final row in yearlyResult) {
      final year = toDouble(row[0]).toInt();
      final revenue = toInt(row[1]);

      ResultRow? expenseRow;
      try {
        expenseRow = yearlyExpensesResult.firstWhere(
          (expRow) => toDouble(expRow[0]).toInt() == year,
        );
      } catch (e) {
        expenseRow = null;
      }

      final expenses = toInt(expenseRow?[1]);
      final profit = revenue - expenses;

      yearlyData.add(
        YearlyData(
          year: year,
          revenue: revenue.toDouble() / 100,
          expenses: expenses.toDouble() / 100,
          profit: profit.toDouble() / 100,
          salesCount: toInt(row[4]),
        ),
      );
    }

    return DashboardData(
      totalRevenue: totalRevenue.toDouble() / 100,
      totalExpenses: totalExpenses.toDouble() / 100,
      totalProfit: totalProfit.toDouble() / 100,
      totalCost: totalCost.toDouble() / 100,
      totalSales: toInt(summary['total_sales']),
      totalProducts: toInt(summary['total_products']),
      lowStockProducts: toInt(summary['low_stock_products']),
      monthlyData: monthlyData,
      yearlyData: yearlyData,
    );
  }

  // Get paginated sales history grouped by invoice
  Future<PaginatedSalesResult> getSalesHistory({
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
    String? invoiceNo,
    String? paymentMethod,
  }) async {
    final conn = await _dbService.connection;

    // Build WHERE clause
    List<String> conditions = [];
    Map<String, dynamic> params = {
      'limit': limit,
      'offset': (page - 1) * limit,
    };

    if (startDate != null) {
      conditions.add('s.created_at >= @startDate');
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      conditions.add('s.created_at <= @endDate');
      params['endDate'] = endDate.toIso8601String();
    }
    if (invoiceNo != null && invoiceNo.isNotEmpty) {
      conditions.add('s.invoice_no ILIKE @invoiceNo');
      params['invoiceNo'] = '%$invoiceNo%';
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      conditions.add('s.payment_method = @paymentMethod');
      params['paymentMethod'] = paymentMethod;
    }

    final whereClause = conditions.isNotEmpty
        ? 'AND ${conditions.join(' AND ')}'
        : '';

    // Get total count of unique invoices
    final countResult = await conn.execute(
      Sql.named('''
        SELECT COUNT(DISTINCT s.invoice_no) as count
        FROM sales s
        WHERE 1=1 $whereClause
      '''),
      parameters: params,
    );
    final totalItems = countResult.first[0] as int;

    // Get paginated sales grouped by invoice
    final salesResult = await conn.execute(
      Sql.named('''
        SELECT
          s.invoice_no,
          s.user_id,
          u.username as user_name,
          s.customer_id,
          s.created_at,
          s.payment_method,
          s.payment_status,
          SUM(s.grand_total) as grand_total,
          SUM(s.sub_total) as sub_total,
          SUM(s.tax_amount) as tax_amount,
          SUM(s.discount_amount) as discount_amount,
          COUNT(*) as item_count,
          STRING_AGG(s.product_name, ', ' ORDER BY s.sale_id) as product_names
        FROM sales s
        LEFT JOIN users u ON s.user_id = u.user_id
        WHERE 1=1 $whereClause
        GROUP BY s.invoice_no, s.user_id, u.username, s.customer_id, s.created_at, s.payment_method, s.payment_status
        ORDER BY s.created_at DESC
        LIMIT @limit OFFSET @offset
      '''),
      parameters: params,
    );

    final sales = salesResult.map((row) {
      final map = row.toColumnMap();
      return Sale(
        saleId: 0, // Not applicable for grouped sales
        invoiceNo: map['invoice_no'] as String,
        userId: map['user_id'] as int,
        userName: map['user_name'] as String?,
        customerId: map['customer_id'] as int?,
        customerName: null, // Would need separate join
        subTotal: map['sub_total'] as double,
        taxAmount: map['tax_amount'] as double? ?? 0,
        discountAmount: map['discount_amount'] as double? ?? 0,
        grandTotal: map['grand_total'] as double,
        paymentMethod: map['payment_method'] as String?,
        paymentStatus: map['payment_status'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();

    return PaginatedSalesResult(
      sales: sales,
      totalItems: totalItems,
      currentPage: page,
      itemsPerPage: limit,
    );
  }

  // Get sale details by invoice number with all items
  Future<SaleWithItems?> getSaleByInvoice(String invoiceNo) async {
    final conn = await _dbService.connection;

    // Get all sale items for this invoice
    final itemsResult = await conn.execute(
      Sql.named('''
        SELECT
          s.sale_id,
          s.product_id,
          s.product_name,
          s.barcode,
          s.quantity,
          s.unit_price,
          s.total_price,
          s.invoice_no,
          s.user_id,
          u.username as user_name,
          s.customer_id,
          s.created_at,
          s.payment_method,
          s.payment_status,
          s.sub_total,
          s.tax_amount,
          s.discount_amount,
          s.grand_total
        FROM sales s
        LEFT JOIN users u ON s.user_id = u.user_id
        WHERE s.invoice_no = @invoiceNo
        ORDER BY s.sale_id
      '''),
      parameters: {'invoiceNo': invoiceNo},
    );

    if (itemsResult.isEmpty) return null;

    // Create sale summary from first item
    final firstRow = itemsResult.first.toColumnMap();
    final sale = Sale(
      saleId: 0,
      invoiceNo: firstRow['invoice_no'] as String,
      userId: firstRow['user_id'] as int,
      userName: firstRow['user_name'] as String?,
      customerId: firstRow['customer_id'] as int?,
      customerName: null,
      subTotal: firstRow['sub_total'] as double,
      taxAmount: firstRow['tax_amount'] as double? ?? 0,
      discountAmount: firstRow['discount_amount'] as double? ?? 0,
      grandTotal: firstRow['grand_total'] as double,
      paymentMethod: firstRow['payment_method'] as String?,
      paymentStatus: firstRow['payment_status'] as String?,
      createdAt: DateTime.parse(firstRow['created_at'] as String),
    );

    // Create sale items
    final items = itemsResult.map((row) {
      final map = row.toColumnMap();
      return SaleItem(
        saleItemId: map['sale_id'] as int,
        saleId: 0,
        productId: map['product_id'] as int,
        productName: map['product_name'] as String?,
        barcode: map['barcode'] as String?,
        quantity: map['quantity'] as int,
        unitPrice: map['unit_price'] as int,
        totalPrice: map['total_price'] as int,
      );
    }).toList();

    return SaleWithItems(
      sale: sale,
      items: items,
      customer: null, // Would need to fetch from customers table separately
    );
  }
}

// Helper class for paginated results
class PaginatedSalesResult {
  final List<Sale> sales;
  final int totalItems;
  final int currentPage;
  final int itemsPerPage;

  PaginatedSalesResult({
    required this.sales,
    required this.totalItems,
    required this.currentPage,
    required this.itemsPerPage,
  });

  int get totalPages => (totalItems / itemsPerPage).ceil();
}
