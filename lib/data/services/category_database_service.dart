import 'package:mini_mart_pos/data/models/product.dart';

import '../../core/services/database_service.dart';

class CategoryDatabaseService {
  final DatabaseService _databaseService;

  CategoryDatabaseService(this._databaseService);

  Future<List<Category>> getAllCategories() async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT * FROM categories WHERE is_active = true ORDER BY category_name',
    );

    return result.map((row) {
      final categoryId = row[0] as int;
      final categoryName = row[1] as String;
      final description = row[2] as String?;

      return Category(
        categoryId: categoryId,
        categoryName: categoryName,
        description: description,
      );
    }).toList();
  }

  Future<Category?> getCategoryById(int categoryId) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT * FROM categories WHERE category_id = \$1 AND is_active = true',
      parameters: [categoryId],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Category(
      categoryId: row[0] as int,
      categoryName: row[1] as String,
      description: row[2] as String?,
    );
  }

  Future<List<Category>> searchCategories(String searchTerm) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      '''SELECT * FROM categories
         WHERE is_active = true AND (
           category_name ILIKE \$1 OR
           description ILIKE \$1
         ) ORDER BY category_name''',
      parameters: ['%$searchTerm%'],
    );

    return result.map((row) {
      return Category(
        categoryId: row[0] as int,
        categoryName: row[1] as String,
        description: row[2] as String?,
      );
    }).toList();
  }

  Future<int> createCategory({
    required String name,
    String? description,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Category name is required');
    }
    if (name.length > 100) {
      throw Exception('Category name must be less than 100 characters');
    }

    final conn = await _databaseService.connection;
    final result = await conn.execute(
      '''INSERT INTO categories (category_name, description, created_at)
         VALUES (\$1, \$2, NOW()) RETURNING category_id''',
      parameters: [name, description],
    );

    return result.first[0] as int;
  }

  Future<void> updateCategory(
    int categoryId, {
    String? name,
    String? description,
  }) async {
    if (name != null) {
      if (name.trim().isEmpty) {
        throw Exception('Category name is required');
      }
      if (name.length > 100) {
        throw Exception('Category name must be less than 100 characters');
      }
    }

    final conn = await _databaseService.connection;

    final updates = <String>[];
    final values = <dynamic>[];
    var paramIndex = 1;

    if (name != null) {
      updates.add('category_name = \$$paramIndex');
      values.add(name);
      paramIndex++;
    }

    if (description != null) {
      updates.add('description = \$$paramIndex');
      values.add(description);
      paramIndex++;
    }

    if (updates.isEmpty) return;

    updates.add('updated_at = NOW()');
    values.add(categoryId);

    final query =
        'UPDATE categories SET ${updates.join(', ')} WHERE category_id = \$$paramIndex';
    await conn.execute(query, parameters: values);
  }

  Future<void> deleteCategory(int categoryId) async {
    final conn = await _databaseService.connection;

    // Check if category is being used by any products
    final productCountResult = await conn.execute(
      'SELECT COUNT(*) as count FROM products WHERE category_id = \$1 AND is_active = true',
      parameters: [categoryId],
    );

    final productCount = productCountResult.first[0] as int;
    if (productCount > 0) {
      throw Exception(
        'Cannot delete category: $productCount products are using this category',
      );
    }

    await conn.execute(
      'UPDATE categories SET is_active = false WHERE category_id = \$1',
      parameters: [categoryId],
    );
  }

  Future<bool> canDeleteCategory(int categoryId) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT COUNT(*) as count FROM products WHERE category_id = \$1 AND is_active = true',
      parameters: [categoryId],
    );

    return (result.first[0] as int) == 0;
  }

  Future<Map<String, dynamic>> getCategoryStatistics(int categoryId) async {
    final conn = await _databaseService.connection;

    // Get product count for this category
    final productCountResult = await conn.execute(
      'SELECT COUNT(*) as count FROM products WHERE category_id = \$1 AND is_active = true',
      parameters: [categoryId],
    );

    // Get total stock quantity for this category
    final stockResult = await conn.execute(
      '''SELECT COALESCE(SUM(stock_quantity), 0) as total_stock
         FROM products WHERE category_id = \$1 AND is_active = true''',
      parameters: [categoryId],
    );

    // Get low stock products count for this category
    final lowStockResult = await conn.execute(
      '''SELECT COUNT(*) as count FROM products
         WHERE category_id = \$1 AND is_active = true
         AND stock_quantity <= reorder_level''',
      parameters: [categoryId],
    );

    return {
      'product_count': productCountResult.first[0] as int,
      'total_stock': stockResult.first[0] as int,
      'low_stock_count': lowStockResult.first[0] as int,
    };
  }

  Future<Map<String, dynamic>> getAllCategoryStatistics() async {
    final conn = await _databaseService.connection;

    // Basic category count
    final categoryCountResult = await conn.execute(
      'SELECT COUNT(*) as count FROM categories WHERE is_active = true',
    );
    final categoryCount = categoryCountResult.first[0] as int;

    // Categories with products
    final categoriesWithProductsResult = await conn.execute(
      '''SELECT COUNT(DISTINCT category_id) as count
         FROM products WHERE is_active = true AND category_id IS NOT NULL''',
    );

    final categoriesWithProducts = categoriesWithProductsResult.first[0] as int;

    // Category-wise product counts
    final categoryStatsResult = await conn.execute(
      '''SELECT c.category_id, c.category_name,
         COUNT(p.product_id) as product_count,
         COALESCE(SUM(p.stock_quantity), 0) as total_stock,
         COALESCE(SUM(CASE WHEN p.stock_quantity <= p.reorder_level THEN 1 ELSE 0 END), 0) as low_stock_count
         FROM categories c
         LEFT JOIN products p ON c.category_id = p.category_id AND p.is_active = true
         WHERE c.is_active = true
         GROUP BY c.category_id, c.category_name
         ORDER BY c.category_name''',
    );

    final categoryStats = categoryStatsResult
        .map(
          (row) => {
            'category_id': row[0] as int,
            'category_name': row[1] as String,
            'product_count': row[2] as int,
            'total_stock': row[3] as int,
            'low_stock_count': row[4] as int,
          },
        )
        .toList();

    return {
      'totalCategories': categoryCount,
      'categoriesWithProducts': categoriesWithProducts,
      'categoryStatistics': categoryStats,
    };
  }

  Future<bool> categoryNameExists(String name, {int? excludeCategoryId}) async {
    final conn = await _databaseService.connection;

    String query =
        'SELECT COUNT(*) as count FROM categories WHERE category_name = \$1 AND is_active = true';
    final values = <dynamic>[name];

    if (excludeCategoryId != null) {
      query += ' AND category_id != \$2';
      values.add(excludeCategoryId);
    }

    final result = await conn.execute(query, parameters: values);
    return (result.first[0] as int) > 0;
  }

  Future<List<Category>> getActiveCategories() async {
    final conn = await _databaseService.connection;
    final result = await conn.execute('''SELECT DISTINCT c.* FROM categories c
         INNER JOIN products p ON c.category_id = p.category_id
         WHERE c.is_active = true AND p.is_active = true
         ORDER BY c.category_name''');

    return result
        .map(
          (row) => Category(
            categoryId: row[0] as int,
            categoryName: row[1] as String,
            description: row[2] as String?,
          ),
        )
        .toList();
  }
}
