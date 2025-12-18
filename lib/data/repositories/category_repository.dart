import '../models/product.dart';
import '../services/category_database_service.dart';
import '../../core/services/database_service.dart';

class CategoryRepository {
  final CategoryDatabaseService _categoryDbService;

  CategoryRepository(DatabaseService dbService) : _categoryDbService = CategoryDatabaseService(dbService);

  // CRUD Operations
  Future<List<Category>> getAllCategories() async {
    try {
      return await _categoryDbService.getAllCategories();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Category?> getCategoryById(int categoryId) async {
    try {
      return await _categoryDbService.getCategoryById(categoryId);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  Future<int> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      // Validate input
      _validateCategoryData(name: name, description: description);

      // Check if category name is already taken
      final isNameTaken = await _categoryDbService.categoryNameExists(name);
      if (isNameTaken) {
        throw Exception('Category name already exists');
      }

      return await _categoryDbService.createCategory(
        name: name.trim(),
        description: description?.trim(),
      );
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<bool> updateCategory(
    int categoryId, {
    String? name,
    String? description,
  }) async {
    try {
      // Validate input if provided
      if (name != null || description != null) {
        final existingCategory = await _categoryDbService.getCategoryById(categoryId);
        if (existingCategory == null) {
          throw Exception('Category not found');
        }

        _validateCategoryData(
          name: name ?? existingCategory.name,
          description: description ?? existingCategory.description,
          isUpdate: true,
        );
      }

      // Check if name is taken by another category
      if (name != null) {
        final isNameTaken = await _categoryDbService.categoryNameExists(name, excludeCategoryId: categoryId);
        if (isNameTaken) {
          throw Exception('Category name already exists');
        }
      }

      await _categoryDbService.updateCategory(
        categoryId,
        name: name?.trim(),
        description: description?.trim(),
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      await _categoryDbService.deleteCategory(categoryId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Search Operations
  Future<List<Category>> searchCategories(String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return getAllCategories();
      }

      return await _categoryDbService.searchCategories(searchTerm.trim());
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  // Business Logic
  Future<List<Category>> getCategoriesWithProducts() async {
    try {
      final allCategories = await getAllCategories();
      final categoriesWithStats = <Category>[];

      for (final category in allCategories) {
        final stats = await _categoryDbService.getCategoryStatistics(category.id);
        if (stats['productCount'] > 0) {
          categoriesWithStats.add(category);
        }
      }

      return categoriesWithStats;
    } catch (e) {
      throw Exception('Failed to fetch categories with products: $e');
    }
  }

  Future<List<Category>> getUnusedCategories() async {
    try {
      final allCategories = await getAllCategories();
      final unusedCategories = <Category>[];

      for (final category in allCategories) {
        final stats = await _categoryDbService.getCategoryStatistics(category.id);
        if (stats['productCount'] == 0) {
          unusedCategories.add(category);
        }
      }

      return unusedCategories;
    } catch (e) {
      throw Exception('Failed to fetch unused categories: $e');
    }
  }

  Future<Map<String, dynamic>> getCategoryStatistics(int categoryId) async {
    try {
      return await _categoryDbService.getCategoryStatistics(categoryId);
    } catch (e) {
      throw Exception('Failed to fetch category statistics: $e');
    }
  }

  Future<Map<String, dynamic>> getAllCategoryStatistics() async {
    try {
      return await _categoryDbService.getAllCategoryStatistics();
    } catch (e) {
      throw Exception('Failed to fetch all category statistics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryUsageReport() async {
    try {
      final allStats = await getAllCategoryStatistics();
      final categoryStats = allStats['categoryStatistics'] as List<Map<String, dynamic>>;

      // Calculate additional metrics
      final report = categoryStats.map((stat) {
        final productCount = stat['productCount'] as int;
        final totalStock = stat['totalStock'] as int;
        final lowStockCount = stat['lowStockCount'] as int;

        // Calculate average stock per product
        final avgStockPerProduct = productCount > 0 ? totalStock / productCount : 0.0;

        // Calculate stock health percentage
        final stockHealthPercentage = productCount > 0
            ? ((productCount - lowStockCount) / productCount) * 100
            : 100.0;

        return {
          ...stat,
          'avgStockPerProduct': avgStockPerProduct,
          'stockHealthPercentage': stockHealthPercentage,
          'hasLowStock': lowStockCount > 0,
          'isEmpty': productCount == 0,
        };
      }).toList();

      // Sort by product count descending
      report.sort((a, b) => (b['productCount'] as int).compareTo(a['productCount'] as int));

      return report;
    } catch (e) {
      throw Exception('Failed to generate category usage report: $e');
    }
  }

  Future<bool> isCategoryNameAvailable(String name, {int? excludeCategoryId}) async {
    try {
      return !(await _categoryDbService.categoryNameExists(name, excludeCategoryId: excludeCategoryId));
    } catch (e) {
      throw Exception('Failed to check category name availability: $e');
    }
  }

  Future<bool> canDeleteCategory(int categoryId) async {
    try {
      final stats = await _categoryDbService.getCategoryStatistics(categoryId);
      return stats['productCount'] == 0;
    } catch (e) {
      throw Exception('Failed to check if category can be deleted: $e');
    }
  }

  Future<int> getTotalProductCountForCategory(int categoryId) async {
    try {
      final stats = await _categoryDbService.getCategoryStatistics(categoryId);
      return stats['productCount'] as int;
    } catch (e) {
      throw Exception('Failed to get product count for category: $e');
    }
  }

  // Validation
  void _validateCategoryData({
    required String name,
    String? description,
    bool isUpdate = false,
  }) {
    // Name validation
    if (name.trim().isEmpty) {
      throw Exception('Category name is required');
    }
    if (name.length > 100) {
      throw Exception('Category name must be less than 100 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-&().]+$').hasMatch(name)) {
      throw Exception('Category name can only contain letters, numbers, spaces, and common symbols');
    }

    // Description validation
    if (description != null && description.isNotEmpty) {
      if (description.length > 500) {
        throw Exception('Description must be less than 500 characters');
      }
    }
  }

  // Helper method to get popular categories
  Future<List<Category>> getPopularCategories({int limit = 5}) async {
    try {
      final allStats = await getAllCategoryStatistics();
      final categoryStats = allStats['categoryStatistics'] as List<Map<String, dynamic>>;

      // Sort by product count and take top categories
      categoryStats.sort((a, b) => (b['productCount'] as int).compareTo(a['productCount'] as int));

      final popularCategoryIds = categoryStats
          .take(limit)
          .map((stat) => stat['categoryId'] as int)
          .toList();

      final allCategories = await getAllCategories();
      return allCategories.where((category) => popularCategoryIds.contains(category.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch popular categories: $e');
    }
  }

  // Helper method to get categories needing attention (low stock products)
  Future<List<Category>> getCategoriesNeedingAttention() async {
    try {
      final allStats = await getAllCategoryStatistics();
      final categoryStats = allStats['categoryStatistics'] as List<Map<String, dynamic>>;

      final attentionCategoryIds = categoryStats
          .where((stat) => (stat['lowStockCount'] as int) > 0)
          .map((stat) => stat['categoryId'] as int)
          .toList();

      final allCategories = await getAllCategories();
      return allCategories.where((category) => attentionCategoryIds.contains(category.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories needing attention: $e');
    }
  }
}