import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';

class PurchaseDatabaseService {
  final DatabaseService _dbService;

  PurchaseDatabaseService(this._dbService);

  // Get all purchases with supplier and user information
  Future<List<Map<String, dynamic>>> getAllPurchases() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        p.*,
        s.company_name as supplier_name,
        u.username as user_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      LEFT JOIN users u ON p.user_id = u.user_id
      ORDER BY p.created_at DESC
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get purchase items with product information
  Future<List<Map<String, dynamic>>> getPurchaseItems(int purchaseId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT
        pi.*,
        pr.product_name,
        pr.barcode
      FROM purchase_items pi
      LEFT JOIN products pr ON pi.product_id = pr.product_id
      WHERE pi.purchase_id = @purchase_id
      ORDER BY pi.item_id
    ''',
      parameters: {'purchase_id': purchaseId},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get supplier information
  Future<Map<String, dynamic>?> getSupplierById(int supplierId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      'SELECT * FROM suppliers WHERE supplier_id = @supplier_id',
      parameters: {'supplier_id': supplierId},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  // Create purchase with items in a transaction
  Future<int> createPurchase({
    required int supplierId,
    required int userId,
    String? supplierInvoiceNo,
    required int totalAmount,
    required String status,
    required DateTime purchaseDate,
    required List<Map<String, dynamic>> items,
  }) async {
    final conn = await _dbService.connection;

    // Start transaction
    await conn.execute('BEGIN');

    try {
      // Insert purchase
      final purchaseResult = await conn.execute(
        '''
        INSERT INTO purchases (
          supplier_id, user_id, supplier_invoice_no, total_amount,
          status, purchase_date, created_at
        ) VALUES (
          @supplier_id, @user_id, @supplier_invoice_no, @total_amount,
          @status, @purchase_date, @created_at
        )
        RETURNING purchase_id
      ''',
        parameters: {
          'supplier_id': supplierId,
          'user_id': userId,
          'supplier_invoice_no': supplierInvoiceNo,
          'total_amount': totalAmount,
          'status': status.toUpperCase(),
          'purchase_date': purchaseDate.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      final purchaseId = purchaseResult.first[0] as int;

      // Insert purchase items
      for (final item in items) {
        await conn.execute(
          '''
          INSERT INTO purchase_items (
            purchase_id, product_id, quantity, buy_price, expiry_date
          ) VALUES (
            @purchase_id, @product_id, @quantity, @buy_price, @expiry_date
          )
        ''',
          parameters: {
            'purchase_id': purchaseId,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'buy_price': item['buy_price'],
            'expiry_date': item['expiry_date'],
          },
        );

        // Update product stock
        await conn.execute(
          '''
          UPDATE products
          SET stock_quantity = stock_quantity + @quantity
          WHERE product_id = @product_id
        ''',
          parameters: {
            'quantity': item['quantity'],
            'product_id': item['product_id'],
          },
        );
      }

      // Commit transaction
      await conn.execute('COMMIT');

      return purchaseId;
    } catch (e) {
      // Rollback on error
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  // Update purchase status
  Future<void> updatePurchaseStatus(int purchaseId, String status) async {
    final conn = await _dbService.connection;

    await conn.execute(
      '''
      UPDATE purchases
      SET status = @status
      WHERE purchase_id = @purchase_id
    ''',
      parameters: {
        'status': status.toUpperCase(),
        'purchase_id': purchaseId,
      },
    );
  }

  // Delete purchase with stock adjustment
  Future<void> deletePurchase(int purchaseId) async {
    final conn = await _dbService.connection;

    // Start transaction
    await conn.execute('BEGIN');

    try {
      // Get purchase items to update stock
      final itemsResult = await conn.execute(
        '''
        SELECT product_id, quantity
        FROM purchase_items
        WHERE purchase_id = @purchase_id
      ''',
      parameters: {'purchase_id': purchaseId},
      );

      // Update product stock (remove the added quantities)
      for (final row in itemsResult) {
        final productId = row[0] as int;
        final quantity = row[1] as int;

        await conn.execute(
          '''
          UPDATE products
          SET stock_quantity = stock_quantity - @quantity
          WHERE product_id = @product_id
        ''',
          parameters: {
            'quantity': quantity,
            'product_id': productId,
          },
        );
      }

      // Delete purchase items
      await conn.execute(
        '''
        DELETE FROM purchase_items
        WHERE purchase_id = @purchase_id
      ''',
      parameters: {'purchase_id': purchaseId},
      );

      // Delete purchase
      await conn.execute(
        '''
        DELETE FROM purchases
        WHERE purchase_id = @purchase_id
      ''',
      parameters: {'purchase_id': purchaseId},
      );

      // Commit transaction
      await conn.execute('COMMIT');
    } catch (e) {
      // Rollback on error
      await conn.execute('ROLLBACK');
      rethrow;
    }
  }

  // Get all suppliers
  Future<List<Map<String, dynamic>>> getAllSuppliers() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT * FROM suppliers
      ORDER BY company_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get all products
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT * FROM products
      WHERE is_active = true
      ORDER BY product_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }
}