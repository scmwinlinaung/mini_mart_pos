import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';
import '../services/inventory_database_service.dart';
import '../models/product.dart';

class InventoryRepository {
  final DatabaseService _databaseService = DatabaseService();
  late final InventoryDatabaseService _inventoryService;

  InventoryRepository() {
    _inventoryService = InventoryDatabaseService(_databaseService);
  }

  // Get all products with current stock levels
  Future<List<Product>> getAllProducts() async {
    try {
      final results = await _inventoryService.getAllProductsWithStock();
      return results.map((row) => Product.fromMap(row)).toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final results = await _inventoryService.getLowStockProducts();
      return results.map((row) => Product.fromMap(row)).toList();
    } catch (e) {
      print('Error getting low stock products: $e');
      return [];
    }
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    try {
      final results = await _inventoryService.getOutOfStockProducts();
      return results.map((row) => Product.fromMap(row)).toList();
    } catch (e) {
      print('Error getting out of stock products: $e');
      return [];
    }
  }

  // Search products by name or barcode
  Future<List<Product>> searchProducts(String query) async {
    try {
      final results = await _inventoryService.searchProducts(query);
      return results.map((row) => Product.fromMap(row)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final result = await _inventoryService.getProductByBarcode(barcode);
      return result != null ? Product.fromMap(result) : null;
    } catch (e) {
      print('Error getting product by barcode: $e');
      return null;
    }
  }

  // Update stock quantity (for manual adjustments)
  Future<bool> updateStockQuantity({
    required int productId,
    required int newQuantity,
    required String reason,
    required int userId,
  }) async {
    try {
      return await _inventoryService.updateStockQuantity(
        productId: productId,
        newQuantity: newQuantity,
        userId: userId,
        reason: reason,
      );
    } catch (e) {
      print('Error updating stock quantity: $e');
      return false;
    }
  }

  // Get stock movement history for a product
  Future<List<StockMovement>> getStockMovementHistory(int productId, {int limit = 100}) async {
    try {
      final results = await _inventoryService.getStockMovementHistory(productId, limit: limit);
      return results.map((row) => StockMovement.fromMap(row)).toList();
    } catch (e) {
      print('Error getting stock movement history: $e');
      return [];
    }
  }

  // Get inventory summary statistics
  Future<Map<String, int>> getInventorySummary() async {
    try {
      final result = await _inventoryService.getInventorySummary();
      return {
        'total_products': result['total_products'] as int? ?? 0,
        'out_of_stock': result['out_of_stock'] as int? ?? 0,
        'low_stock': result['low_stock'] as int? ?? 0,
        'active_products': result['active_products'] as int? ?? 0,
      };
    } catch (e) {
      print('Error getting inventory summary: $e');
      return {
        'total_products': 0,
        'out_of_stock': 0,
        'low_stock': 0,
        'active_products': 0,
      };
    }
  }
}

class StockMovement {
  final int movementId;
  final int productId;
  final int userId;
  final String username;
  final String movementType;
  final int quantity;
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    required this.movementId,
    required this.productId,
    required this.userId,
    required this.username,
    required this.movementType,
    required this.quantity,
    this.notes,
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      movementId: map['movement_id'] as int,
      productId: map['product_id'] as int,
      userId: map['user_id'] as int,
      username: map['username'] as String,
      movementType: map['movement_type'] as String,
      quantity: map['quantity'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get formattedQuantity {
    final prefix = quantity >= 0 ? '+' : '';
    return '$prefix$quantity';
  }

  String get movementTypeDisplay {
    switch (movementType.toUpperCase()) {
      case 'SALE':
        return 'Sale';
      case 'PURCHASE':
        return 'Purchase';
      case 'RETURN':
        return 'Return';
      case 'ADJUSTMENT':
        return 'Adjustment';
      default:
        return movementType;
    }
  }
}