import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';

class InventoryDatabaseService {
  final DatabaseService _dbService;

  InventoryDatabaseService(this._dbService);

  // Get all products with current stock levels
  Future<List<Map<String, dynamic>>> getAllProductsWithStock() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        p.product_id,
        p.barcode,
        p.product_name,
        p.description,
        p.category_id,
        c.category_name,
        p.supplier_id,
        s.company_name as supplier_name,
        p.cost_price,
        p.sell_price,
        p.stock_quantity,
        p.reorder_level,
        p.is_active,
        p.created_at,
        p.updated_at
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      ORDER BY p.product_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        p.product_id,
        p.barcode,
        p.product_name,
        p.description,
        p.category_id,
        c.category_name,
        p.supplier_id,
        s.company_name as supplier_name,
        p.cost_price,
        p.sell_price,
        p.stock_quantity,
        p.reorder_level,
        p.is_active,
        p.created_at,
        p.updated_at
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE p.stock_quantity <= p.reorder_level AND p.is_active = true
      ORDER BY p.stock_quantity ASC
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get out of stock products
  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        p.product_id,
        p.barcode,
        p.product_name,
        p.description,
        p.category_id,
        c.category_name,
        p.supplier_id,
        s.company_name as supplier_name,
        p.cost_price,
        p.sell_price,
        p.stock_quantity,
        p.reorder_level,
        p.is_active,
        p.created_at,
        p.updated_at
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE p.stock_quantity <= 0 AND p.is_active = true
      ORDER BY p.product_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Search products by name or barcode
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        p.product_id,
        p.barcode,
        p.product_name,
        p.description,
        p.category_id,
        c.category_name,
        p.supplier_id,
        s.company_name as supplier_name,
        p.cost_price,
        p.sell_price,
        p.stock_quantity,
        p.reorder_level,
        p.is_active,
        p.created_at,
        p.updated_at
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE (p.product_name ILIKE @query OR p.barcode ILIKE @query) AND p.is_active = true
      ORDER BY p.product_name
      LIMIT 50
    '''),
      parameters: {'query': '%$query%'},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get product by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        p.product_id,
        p.barcode,
        p.product_name,
        p.description,
        p.category_id,
        c.category_name,
        p.supplier_id,
        s.company_name as supplier_name,
        p.cost_price,
        p.sell_price,
        p.stock_quantity,
        p.reorder_level,
        p.is_active,
        p.created_at,
        p.updated_at
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE p.barcode = @barcode AND p.is_active = true
      LIMIT 1
    '''),
      parameters: {'barcode': barcode},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  // Update stock quantity with transaction
  Future<bool> updateStockQuantity({
    required int productId,
    required int newQuantity,
    required int userId,
    required String reason,
  }) async {
    final conn = await _dbService.connection;

    return await conn.runTx((txn) async {
      // Get current stock quantity
      final currentResult = await txn.execute(
        Sql.named('SELECT stock_quantity FROM products WHERE product_id = @product_id'),
        parameters: {'product_id': productId},
      );

      if (currentResult.isEmpty) return false;

      final currentQuantity = currentResult.first[0] as int;
      final adjustment = newQuantity - currentQuantity;

      if (adjustment == 0) return true; // No change needed

      // Update product stock
      final updateResult = await txn.execute(
        Sql.named('''
        UPDATE products
        SET stock_quantity = @new_quantity, updated_at = NOW()
        WHERE product_id = @product_id
      '''),
        parameters: {
          'new_quantity': newQuantity,
          'product_id': productId,
        },
      );

      // Record stock movement
      await txn.execute(
        Sql.named('''
        INSERT INTO stock_movements (product_id, user_id, movement_type, quantity, notes, created_at)
        VALUES (@product_id, @user_id, 'ADJUSTMENT', @adjustment, @reason, NOW())
      '''),
        parameters: {
          'product_id': productId,
          'user_id': userId,
          'adjustment': adjustment,
          'reason': reason,
        },
      );

      return updateResult.affectedRows > 0;
    });
  }

  // Get stock movement history for a product
  Future<List<Map<String, dynamic>>> getStockMovementHistory(int productId, {int limit = 100}) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        sm.movement_id,
        sm.product_id,
        sm.user_id,
        u.username,
        sm.movement_type,
        sm.quantity,
        sm.notes,
        sm.created_at
      FROM stock_movements sm
      JOIN users u ON sm.user_id = u.user_id
      WHERE sm.product_id = @product_id
      ORDER BY sm.created_at DESC
      LIMIT @limit
    '''),
      parameters: {
        'product_id': productId,
        'limit': limit,
      },
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get inventory summary statistics
  Future<Map<String, dynamic>> getInventorySummary() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        COUNT(*) as total_products,
        COUNT(CASE WHEN stock_quantity <= 0 THEN 1 END) as out_of_stock,
        COUNT(CASE WHEN stock_quantity <= reorder_level AND stock_quantity > 0 THEN 1 END) as low_stock,
        COUNT(CASE WHEN is_active = true THEN 1 END) as active_products
      FROM products
    ''');

    return result.first.toColumnMap();
  }

  // Create stock movement entry
  Future<int> createStockMovement({
    required int productId,
    required int userId,
    required String movementType,
    required int quantity,
    String? notes,
  }) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      INSERT INTO stock_movements (product_id, user_id, movement_type, quantity, notes, created_at)
      VALUES (@product_id, @user_id, @movement_type, @quantity, @notes, NOW())
      RETURNING movement_id
    '''),
      parameters: {
        'product_id': productId,
        'user_id': userId,
        'movement_type': movementType,
        'quantity': quantity,
        'notes': notes,
      },
    );

    return result.first[0] as int;
  }

  // Get recent stock movements
  Future<List<Map<String, dynamic>>> getRecentStockMovements({int limit = 50}) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        sm.movement_id,
        sm.product_id,
        p.product_name,
        p.barcode,
        sm.user_id,
        u.username,
        sm.movement_type,
        sm.quantity,
        sm.notes,
        sm.created_at
      FROM stock_movements sm
      JOIN products p ON sm.product_id = p.product_id
      JOIN users u ON sm.user_id = u.user_id
      ORDER BY sm.created_at DESC
      LIMIT @limit
    '''),
      parameters: {'limit': limit},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }
}