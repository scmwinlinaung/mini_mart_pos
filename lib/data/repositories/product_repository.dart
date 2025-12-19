import '../models/product.dart';
import '../../core/services/database_service.dart';
import '../services/product_database_service.dart';

class ProductRepository {
  final ProductDatabaseService _productDbService;

  ProductRepository(DatabaseService dbService)
    : _productDbService = ProductDatabaseService(dbService);

  // Get all products
  Future<List<Product>> getAllProducts(int page, int limit) async {
    final productsData = await _productDbService.getAllProducts(
      page: page,
      limit: limit,
    );
    return productsData.map((data) => Product.fromMap(data)).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(int productId) async {
    final productData = await _productDbService.getProductById(productId);
    if (productData == null) return null;
    return Product.fromMap(productData);
  }

  // Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final productsData = await _productDbService.searchProducts(barcode);
    if (productsData.isEmpty) return null;
    return Product.fromMap(productsData.first);
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final productsData = await _productDbService.searchProducts(query);
    return productsData.map((data) => Product.fromMap(data)).toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final productsData = await _productDbService.getProductsByCategory(
      categoryId,
    );
    return productsData.map((data) => Product.fromMap(data)).toList();
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final productsData = await _productDbService.getLowStockProducts();
    return productsData.map((data) => Product.fromMap(data)).toList();
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final productsData = await _productDbService.getOutOfStockProducts();
    return productsData.map((data) => Product.fromMap(data)).toList();
  }

  // Add new product
  Future<int> addProduct({
    required String barcode,
    required String productName,
    String? description,
    required int categoryId,
    required int supplierId,
    required int unitTypeId,
    required int costPrice,
    required int sellPrice,
    required int stockQuantity,
    int reorderLevel = 10,
    bool isActive = true,
  }) async {
    // Check if barcode already exists
    if (await _productDbService.barcodeExists(barcode)) {
      throw Exception('Barcode already exists');
    }

    final productData = {
      'barcode': barcode,
      'product_name': productName,
      'description': description,
      'category_id': categoryId,
      'supplier_id': supplierId,
      'unit_type_id': unitTypeId,
      'cost_price': costPrice, // Convert to cents
      'sell_price': sellPrice, // Convert to cents
      'stock_quantity': stockQuantity,
      'reorder_level': reorderLevel,
      'is_active': isActive,
    };

    return await _productDbService.insertProduct(productData);
  }

  // Update product
  Future<bool> updateProduct(
    int productId, {
    String? barcode,
    String? productName,
    String? description,
    int? categoryId,
    int? supplierId,
    int? unitTypeId,
    int? costPrice,
    int? sellPrice,
    int? stockQuantity,
    int? reorderLevel,
    bool? isActive,
  }) async {
    // Check if barcode exists (if updating barcode)
    if (barcode != null) {
      if (await _productDbService.barcodeExists(
        barcode,
        excludeProductId: productId,
      )) {
        throw Exception('Barcode already exists');
      }
    }

    final productData = <String, dynamic>{};

    if (barcode != null) productData['barcode'] = barcode;
    if (productName != null) productData['product_name'] = productName;
    if (description != null) productData['description'] = description;
    if (categoryId != null) productData['category_id'] = categoryId;
    if (supplierId != null) productData['supplier_id'] = supplierId;
    if (unitTypeId != null) productData['unit_type_id'] = unitTypeId;
    if (costPrice != null) productData['cost_price'] = costPrice;
    if (sellPrice != null) productData['sell_price'] = sellPrice;
    if (stockQuantity != null) productData['stock_quantity'] = stockQuantity;
    if (reorderLevel != null) productData['reorder_level'] = reorderLevel;
    if (isActive != null) productData['is_active'] = isActive;

    return await _productDbService.updateProduct(productId, productData);
  }

  // Update product stock
  Future<bool> updateProductStock(int productId, int newQuantity) async {
    return await _productDbService.updateProductStock(productId, newQuantity);
  }

  // Adjust stock quantity (add or remove)
  Future<bool> adjustProductStock(
    int productId,
    int adjustment, {
    String? notes,
  }) async {
    final product = await getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }

    final newQuantity = product.stockQuantity + adjustment;
    if (newQuantity < 0) {
      throw Exception('Insufficient stock');
    }

    return await _productDbService.updateProductStock(productId, newQuantity);
  }

  // Deactivate product (soft delete)
  Future<bool> deactivateProduct(int productId) async {
    return await _productDbService.deactivateProduct(productId);
  }

  // Activate product
  Future<bool> activateProduct(int productId) async {
    return await _productDbService.activateProduct(productId);
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    final stats = await _productDbService.getProductStatistics();

    // Convert cents back to dollars for display
    return {
      'total_products': stats['total_products'],
      'active_products': stats['active_products'],
      'out_of_stock': stats['out_of_stock'],
      'low_stock': stats['low_stock'],
      'avg_sell_price': (stats['avg_sell_price'] ?? 0) / 100.0,
      'avg_cost_price': (stats['avg_cost_price'] ?? 0) / 100.0,
      'total_stock_value': (stats['total_stock_value'] ?? 0) / 100.0,
      'total_retail_value': (stats['total_retail_value'] ?? 0) / 100.0,
    };
  }

  // Get categories
  Future<List<Category>> getAllCategories() async {
    final categoriesData = await _productDbService.getAllCategories();
    return categoriesData.map((data) => Category.fromMap(data)).toList();
  }

  // Add category
  Future<int> addCategory(String categoryName) async {
    return await _productDbService.insertCategory(categoryName);
  }

  // Update category
  Future<bool> updateCategory(int categoryId, String categoryName) async {
    return await _productDbService.updateCategory(categoryId, categoryName);
  }

  // Delete category
  Future<bool> deleteCategory(int categoryId) async {
    try {
      return await _productDbService.deleteCategory(categoryId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Get suppliers
  Future<List<Supplier>> getAllSuppliers() async {
    final suppliersData = await _productDbService.getAllSuppliers();
    return suppliersData.map((data) => Supplier.fromMap(data)).toList();
  }

  // Add supplier
  Future<int> addSupplier({
    required String companyName,
    String? contactName,
    String? phoneNumber,
    String? address,
  }) async {
    final supplierData = {
      'company_name': companyName,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'address': address,
    };

    return await _productDbService.insertSupplier(supplierData);
  }

  // Update supplier
  Future<bool> updateSupplier(
    int supplierId, {
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? address,
  }) async {
    final supplierData = <String, dynamic>{};

    if (companyName != null) supplierData['company_name'] = companyName;
    if (contactName != null) supplierData['contact_name'] = contactName;
    if (phoneNumber != null) supplierData['phone_number'] = phoneNumber;
    if (address != null) supplierData['address'] = address;

    return await _productDbService.updateSupplier(supplierId, supplierData);
  }

  // Delete supplier
  Future<bool> deleteSupplier(int supplierId) async {
    try {
      return await _productDbService.deleteSupplier(supplierId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Get unit types
  Future<List<UnitType>> getAllUnitTypes() async {
    final unitTypesData = await _productDbService.getAllUnitTypes();
    return unitTypesData.map((data) => UnitType.fromMap(data)).toList();
  }
}
