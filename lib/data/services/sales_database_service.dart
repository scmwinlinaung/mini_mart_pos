import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';

class SalesDatabaseService {
  final DatabaseService _dbService;

  SalesDatabaseService(this._dbService);

  // Create new sale with items
  // Note: Schema stores each sale line item directly in the sales table
  Future<int> createSale({
    required String invoiceNo,
    required int userId,
    int? customerId,
    required int subTotal,
    required int taxAmount,
    required int discountAmount,
    required int grandTotal,
    required String paymentMethod,
    required List<Map<String, dynamic>> saleItems,
  }) async {
    final conn = await _dbService.connection;

    return await conn.runTx((txn) async {
      // Insert each sale item as a separate row in the sales table
      int firstSaleId = 0;

      for (final item in saleItems) {
        final saleResult = await txn.execute(
          Sql.named('''
          INSERT INTO sales (
            invoice_no, user_id, customer_id,
            product_id, unit_type_id, barcode, product_name,
            quantity, unit_price, total_price,
            tax_amount, discount_amount, sub_total, grand_total,
            payment_method, payment_status
          ) VALUES (
            @invoice_no, @user_id, @customer_id,
            @product_id, @unit_type_id, @barcode, @product_name,
            @quantity, @unit_price, @total_price,
            @tax_amount, @discount_amount, @sub_total, @grand_total,
            @payment_method, 'PAID'
          ) RETURNING sale_id
        '''),
          parameters: {
            'invoice_no': invoiceNo,
            'user_id': userId,
            'customer_id': customerId,
            'product_id': item['product_id'],
            'unit_type_id': item['unit_type_id'],
            'barcode': item['barcode'],
            'product_name': item['product_name'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'total_price': item['total_price'],
            'tax_amount': taxAmount,
            'discount_amount': discountAmount,
            'sub_total': subTotal,
            'grand_total': grandTotal,
            'payment_method': paymentMethod,
          },
        );

        // Store the first sale_id
        if (firstSaleId == 0) {
          firstSaleId = saleResult.first[0] as int;
        }
      }

      return firstSaleId;
    });
  }

  // Get sales by date range
  Future<List<Map<String, dynamic>>> getSalesByDateRange(DateTime startDate, DateTime endDate) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        s.sale_id,
        s.invoice_no,
        s.user_id,
        u.username as cashier_name,
        s.customer_id,
        c.full_name as customer_name,
        s.sub_total,
        s.tax_amount,
        s.discount_amount,
        s.grand_total,
        s.payment_method,
        s.payment_status,
        s.created_at
      FROM sales s
      JOIN users u ON s.user_id = u.user_id
      LEFT JOIN customers c ON s.customer_id = c.customer_id
      WHERE s.created_at >= @start_date AND s.created_at <= @end_date
      ORDER BY s.created_at DESC
    '''),
      parameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get sale items for a specific invoice
  Future<List<Map<String, dynamic>>> getSaleItemsByInvoice(String invoiceNo) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        s.sale_id,
        s.invoice_no,
        s.product_id,
        s.product_name,
        s.barcode,
        s.quantity,
        s.unit_price,
        s.total_price,
        s.grand_total
      FROM sales s
      WHERE s.invoice_no = @invoice_no
      ORDER BY s.sale_id
    '''),
      parameters: {'invoice_no': invoiceNo},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get sales summary for dashboard
  Future<Map<String, dynamic>> getSalesSummary(DateTime startDate, DateTime endDate) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        COUNT(DISTINCT s.invoice_no) as total_sales,
        COUNT(DISTINCT s.user_id) as number_of_cashiers,
        SUM(s.grand_total) as total_revenue,
        AVG(s.grand_total) as average_sale_value,
        SUM(s.discount_amount) as total_discounts,
        SUM(s.quantity) as total_items_sold
      FROM sales s
      WHERE s.created_at >= @start_date AND s.created_at <= @end_date
    '''),
      parameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );

    final summary = result.first.toColumnMap();
    // Convert to proper types (handle null values)
    return {
      'total_sales': summary['total_sales'] as int? ?? 0,
      'number_of_cashiers': summary['number_of_cashiers'] as int? ?? 0,
      'total_revenue': summary['total_revenue'] as int? ?? 0,
      'average_sale_value': (summary['average_sale_value'] as num?)?.toInt() ?? 0,
      'total_discounts': summary['total_discounts'] as int? ?? 0,
      'total_items_sold': summary['total_items_sold'] as int? ?? 0,
    };
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime startDate, DateTime endDate, {int limit = 10}) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        s.product_id,
        s.product_name,
        s.barcode,
        SUM(s.quantity) as total_quantity_sold,
        SUM(s.total_price) as total_revenue,
        COUNT(DISTINCT s.invoice_no) as number_of_transactions
      FROM sales s
      WHERE s.created_at >= @start_date AND s.created_at <= @end_date
      GROUP BY s.product_id, s.product_name, s.barcode
      ORDER BY total_quantity_sold DESC
      LIMIT @limit
    '''),
      parameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'limit': limit,
      },
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get today's sales
  Future<List<Map<String, dynamic>>> getTodaySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getSalesByDateRange(startOfDay, endOfDay);
  }

  // Get sales by payment method
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod(DateTime startDate, DateTime endDate) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        payment_method,
        COUNT(*) as number_of_sales,
        SUM(grand_total) as total_amount
      FROM sales
      WHERE created_at >= @start_date AND created_at <= @end_date
      GROUP BY payment_method
      ORDER BY total_amount DESC
    '''),
      parameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Search sales by invoice number
  Future<List<Map<String, dynamic>>> searchSales(String invoiceNo) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        s.sale_id,
        s.invoice_no,
        s.user_id,
        u.username as cashier_name,
        s.customer_id,
        c.full_name as customer_name,
        s.grand_total,
        s.payment_method,
        s.payment_status,
        s.created_at
      FROM sales s
      JOIN users u ON s.user_id = u.user_id
      LEFT JOIN customers c ON s.customer_id = c.customer_id
      WHERE s.invoice_no ILIKE @invoice_no
      ORDER BY s.created_at DESC
      LIMIT 50
    '''),
      parameters: {'invoice_no': '%$invoiceNo%'},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }
}