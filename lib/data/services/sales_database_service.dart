import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';

class SalesDatabaseService {
  final DatabaseService _dbService;

  SalesDatabaseService(this._dbService);

  // Create new sale with items
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
      // Create sale record
      final saleResult = await txn.execute(
        Sql.named('''
        INSERT INTO sales (
          invoice_no, user_id, customer_id, sub_total, tax_amount,
          discount_amount, grand_total, payment_method, payment_status
        ) VALUES (
          @invoice_no, @user_id, @customer_id, @sub_total, @tax_amount,
          @discount_amount, @grand_total, @payment_method, 'PAID'
        ) RETURNING sale_id
      '''),
        parameters: {
          'invoice_no': invoiceNo,
          'user_id': userId,
          'customer_id': customerId,
          'sub_total': subTotal,
          'tax_amount': taxAmount,
          'discount_amount': discountAmount,
          'grand_total': grandTotal,
          'payment_method': paymentMethod,
        },
      );

      final saleId = saleResult.first[0] as int;

      // Create sale items
      for (final item in saleItems) {
        await txn.execute(
          Sql.named('''
          INSERT INTO sale_items (
            sale_id, product_id, quantity, unit_price, total_price
          ) VALUES (
            @sale_id, @product_id, @quantity, @unit_price, @total_price
          )
        '''),
          parameters: {
            'sale_id': saleId,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
            'total_price': item['total_price'],
          },
        );
      }

      return saleId;
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

  // Get sale items for a specific sale
  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        si.sale_item_id,
        si.sale_id,
        si.product_id,
        p.product_name,
        p.barcode,
        si.quantity,
        si.unit_price,
        si.total_price
      FROM sale_items si
      JOIN products p ON si.product_id = p.product_id
      WHERE si.sale_id = @sale_id
      ORDER BY si.sale_item_id
    '''),
      parameters: {'sale_id': saleId},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get sales summary for dashboard
  Future<Map<String, dynamic>> getSalesSummary(DateTime startDate, DateTime endDate) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        COUNT(*) as total_sales,
        COUNT(DISTINCT s.user_id) as number_of_cashiers,
        SUM(s.grand_total) as total_revenue,
        AVG(s.grand_total) as average_sale_value,
        SUM(s.discount_amount) as total_discounts,
        SUM(si.quantity) as total_items_sold
      FROM sales s
      JOIN sale_items si ON s.sale_id = si.sale_id
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
        p.product_id,
        p.product_name,
        p.barcode,
        SUM(si.quantity) as total_quantity_sold,
        SUM(si.total_price) as total_revenue,
        COUNT(DISTINCT s.sale_id) as number_of_transactions
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.sale_id
      JOIN products p ON si.product_id = p.product_id
      WHERE s.created_at >= @start_date AND s.created_at <= @end_date
      GROUP BY p.product_id, p.product_name, p.barcode
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