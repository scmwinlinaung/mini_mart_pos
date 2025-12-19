import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';

class ProductDatabaseService {
  final DatabaseService _dbService;

  ProductDatabaseService(this._dbService);

  // Get all products with categories, suppliers, and unit types
  Future<List<Map<String, dynamic>>> getAllProducts({
    int page = 1,
    int limit = 20,
  }) async {
    final conn = await _dbService.connection;
    final offset = (page - 1) * limit;
    final result = await conn.execute(
      '''
      SELECT
        p.*,
        c.category_name,
        s.company_name,
        s.contact_name,
        u.unit_code,
        u.unit_name,
        p.is_active
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      LEFT JOIN unit_types u ON p.unit_type_id = u.unit_id
      WHERE p.is_active = true
      ORDER BY p.product_name
      LIMIT \$1 OFFSET \$2
    ''',
      parameters: [limit, offset],
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get product by ID
  Future<Map<String, dynamic>?> getProductById(int productId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT
        p.*,
        c.category_name,
        s.company_name,
        s.contact_name,
        u.unit_code,
        u.unit_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      LEFT JOIN unit_types u ON p.unit_type_id = u.unit_id
      WHERE p.product_id = @product_id
    ''',
      parameters: {'product_id': productId},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  // Search products by barcode or name
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT
        p.*,
        c.category_name,
        s.company_name,
        s.contact_name,
        u.unit_code,
        u.unit_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      LEFT JOIN unit_types u ON p.unit_type_id = u.unit_id
      WHERE
        p.is_active = true AND (
        p.barcode ILIKE @query OR
        p.product_name ILIKE @query OR
        p.description ILIKE @query)
      ORDER BY p.product_name
      LIMIT 50
    ''',
      parameters: {'query': '%$query%'},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    int categoryId,
  ) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT
        p.*,
        c.category_name,
        s.company_name,
        s.contact_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE p.category_id = @category_id AND p.is_active = true
      ORDER BY p.product_name
    ''',
      parameters: {'category_id': categoryId},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        p.*,
        c.category_name,
        s.company_name,
        s.contact_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE p.stock_quantity <= p.reorder_level AND p.is_active = true
      ORDER BY p.stock_quantity ASC, p.product_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get out of stock products
  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        p.*,
        c.category_name,
        s.company_name,
        s.contact_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.category_id
      LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
      WHERE p.stock_quantity <= 0 AND p.is_active = true
      ORDER BY p.product_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Insert new product
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO products (
          barcode, product_name, description, category_id, supplier_id, unit_type_id,
          cost_price, sell_price, stock_quantity, reorder_level, is_active
        ) VALUES (
          @barcode, @product_name, @description, @category_id, @supplier_id, @unit_type_id,
          @cost_price, @sell_price, @stock_quantity, @reorder_level, @is_active
        ) RETURNING product_id
      '''),
      parameters: product,
    );

    return result.first[0] as int;
  }

  // Update product
  Future<bool> updateProduct(
    int productId,
    Map<String, dynamic> product,
  ) async {
    final conn = await _dbService.connection;

    // Build dynamic UPDATE query
    final updates = <String>[];
    final params = <String, dynamic>{'product_id': productId};

    product.forEach((key, value) {
      if (value != null) {
        updates.add('$key = @$key');
        params[key] = value;
      }
    });

    if (updates.isEmpty) return false;

    final sql =
        '''
      UPDATE products
      SET ${updates.join(', ')}, updated_at = NOW()
      WHERE product_id = @product_id
    ''';

    final result = await conn.execute(Sql.named(sql), parameters: params);
    return result.affectedRows > 0;
  }

  // Update product stock quantity
  Future<bool> updateProductStock(int productId, int newQuantity) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        UPDATE products
        SET stock_quantity = @quantity, updated_at = NOW()
        WHERE product_id = @product_id
      '''),
      parameters: {'product_id': productId, 'quantity': newQuantity},
    );

    return result.affectedRows > 0;
  }

  // Deactivate product (soft delete)
  Future<bool> deactivateProduct(int productId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        DELETE from products
        WHERE product_id = @product_id
      '''),
      parameters: {'product_id': productId},
    );

    return result.affectedRows > 0;
  }

  // Activate product
  Future<bool> activateProduct(int productId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        UPDATE products
        SET is_active = true, updated_at = NOW()
        WHERE product_id = @product_id
      '''),
      parameters: {'product_id': productId},
    );

    return result.affectedRows > 0;
  }

  // Check if barcode exists
  Future<bool> barcodeExists(String barcode, {int? excludeProductId}) async {
    final conn = await _dbService.connection;

    String sql = 'SELECT COUNT(*) FROM products WHERE barcode = @barcode';
    var params = <String, dynamic>{'barcode': barcode};

    if (excludeProductId != null) {
      sql += ' AND product_id != @exclude_id';
      params['exclude_id'] = excludeProductId;
    }

    final result = await conn.execute(Sql.named(sql), parameters: params);
    final count = result.first.first as int;
    return count > 0;
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        COUNT(*) as total_products,
        COUNT(CASE WHEN is_active = true THEN 1 END) as active_products,
        COUNT(CASE WHEN stock_quantity <= 0 THEN 1 END) as out_of_stock,
        COUNT(CASE WHEN stock_quantity <= reorder_level AND stock_quantity > 0 THEN 1 END) as low_stock,
        AVG(sell_price) as avg_sell_price,
        AVG(cost_price) as avg_cost_price,
        SUM(stock_quantity) as total_stock_value,
        SUM(stock_quantity * sell_price) as total_retail_value
      FROM products
    ''');

    return result.first.toColumnMap();
  }

  // === CATEGORY MANAGEMENT METHODS ===

  // Get all categories
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        c.*,
        COUNT(p.product_id) as product_count
      FROM categories c
      LEFT JOIN products p ON c.category_id = p.category_id AND p.is_active = true
      GROUP BY c.category_id, c.category_name
      ORDER BY c.category_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(int categoryId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT * FROM categories WHERE category_id = @category_id
    ''',
      parameters: {'category_id': categoryId},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  // Insert new category
  Future<int> insertCategory(String categoryName) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO categories (category_name)
        VALUES (@category_name)
        RETURNING category_id
      '''),
      parameters: {'category_name': categoryName},
    );

    return result.first[0] as int;
  }

  // Update category
  Future<bool> updateCategory(int categoryId, String categoryName) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        UPDATE categories
        SET category_name = @category_name
        WHERE category_id = @category_id
      '''),
      parameters: {'category_id': categoryId, 'category_name': categoryName},
    );

    return result.affectedRows > 0;
  }

  // Delete category (check if products exist first)
  Future<bool> deleteCategory(int categoryId) async {
    final conn = await _dbService.connection;

    // Check if category has products
    final productCountResult = await conn.execute(
      Sql.named(
        'SELECT COUNT(*) FROM products WHERE category_id = @category_id',
      ),
      parameters: {'category_id': categoryId},
    );
    final productCount = productCountResult.first.first as int;

    if (productCount > 0) {
      throw Exception('Cannot delete category with existing products');
    }

    final result = await conn.execute(
      Sql.named('DELETE FROM categories WHERE category_id = @category_id'),
      parameters: {'category_id': categoryId},
    );

    return result.affectedRows > 0;
  }

  // === SUPPLIER MANAGEMENT METHODS ===

  // Get all suppliers
  Future<List<Map<String, dynamic>>> getAllSuppliers() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        s.*,
        COUNT(p.product_id) as product_count
      FROM suppliers s
      LEFT JOIN products p ON s.supplier_id = p.supplier_id AND p.is_active = true
      GROUP BY s.supplier_id, s.company_name, s.contact_name, s.phone_number, s.address
      ORDER BY s.company_name
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get supplier by ID
  Future<Map<String, dynamic>?> getSupplierById(int supplierId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT * FROM suppliers WHERE supplier_id = @supplier_id
    ''',
      parameters: {'supplier_id': supplierId},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  // Insert new supplier
  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO suppliers (company_name, contact_name, phone_number, address)
        VALUES (@company_name, @contact_name, @phone_number, @address)
        RETURNING supplier_id
      '''),
      parameters: supplier,
    );

    return result.first[0] as int;
  }

  // Update supplier
  Future<bool> updateSupplier(
    int supplierId,
    Map<String, dynamic> supplier,
  ) async {
    final conn = await _dbService.connection;

    // Build dynamic UPDATE query
    final updates = <String>[];
    final params = <String, dynamic>{'supplier_id': supplierId};

    supplier.forEach((key, value) {
      if (value != null) {
        updates.add('$key = @$key');
        params[key] = value;
      }
    });

    if (updates.isEmpty) return false;

    final sql =
        '''
      UPDATE suppliers
      SET ${updates.join(', ')}
      WHERE supplier_id = @supplier_id
    ''';

    final result = await conn.execute(Sql.named(sql), parameters: params);
    return result.affectedRows > 0;
  }

  // Delete supplier (check if products exist first)
  Future<bool> deleteSupplier(int supplierId) async {
    final conn = await _dbService.connection;

    // Check if supplier has products
    final productCountResult = await conn.execute(
      Sql.named(
        'SELECT COUNT(*) FROM products WHERE supplier_id = @supplier_id',
      ),
      parameters: {'supplier_id': supplierId},
    );
    final productCount = productCountResult.first.first as int;

    if (productCount > 0) {
      throw Exception('Cannot delete supplier with existing products');
    }

    final result = await conn.execute(
      Sql.named('DELETE FROM suppliers WHERE supplier_id = @supplier_id'),
      parameters: {'supplier_id': supplierId},
    );

    return result.affectedRows > 0;
  }

  // === UNIT TYPE MANAGEMENT METHODS ===

  // Get all unit types
  Future<List<Map<String, dynamic>>> getAllUnitTypes() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        u.*,
        COUNT(p.product_id) as product_count
      FROM unit_types u
      LEFT JOIN products p ON u.unit_id = p.unit_type_id AND p.is_active = true
      GROUP BY u.unit_id, u.unit_code, u.unit_name, u.is_weighted, u.created_at
      ORDER BY u.unit_code
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get unit type by ID
  Future<Map<String, dynamic>?> getUnitTypeById(int unitId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      '''
      SELECT * FROM unit_types WHERE unit_id = @unit_id
    ''',
      parameters: {'unit_id': unitId},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }
}
