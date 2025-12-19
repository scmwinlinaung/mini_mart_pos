import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/core/service_locator.dart';
import 'package:mini_mart_pos/core/services/database_service.dart';
import 'package:mini_mart_pos/data/models/product.dart';
import 'package:mini_mart_pos/data/repositories/product_repository.dart';

// Product filter enum
enum ProductFilter { all, inStock, lowStock, outOfStock }

// Product state
class ProductState {
  final List<Product> products;
  final Product? selectedProduct;
  final ProductFilter filter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  // Pagination state
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  // Form state
  final bool isEditing;
  final String? barcodeError;
  final String? productNameError;
  final String? sellPriceError;
  final String? stockQuantityError;

  const ProductState({
    this.products = const [],
    this.selectedProduct,
    this.filter = ProductFilter.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.itemsPerPage = 20,
    this.totalItems = 0,
    this.isEditing = false,
    this.barcodeError,
    this.productNameError,
    this.sellPriceError,
    this.stockQuantityError,
  });

  ProductState copyWith({
    List<Product>? products,
    Product? selectedProduct,
    ProductFilter? filter,
    String? searchQuery,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? itemsPerPage,
    int? totalItems,
    bool? isEditing,
    String? barcodeError,
    String? productNameError,
    String? sellPriceError,
    String? stockQuantityError,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedProduct: selectedProduct,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
      isEditing: isEditing ?? this.isEditing,
      barcodeError: barcodeError,
      productNameError: productNameError,
      sellPriceError: sellPriceError,
      stockQuantityError: stockQuantityError,
    );
  }

  // Helper method for state pattern matching
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<Product> products, Product? selectedProduct)
    loaded,
    required T Function(String message) error,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error!);
    } else {
      return loaded(products, selectedProduct);
    }
  }
}

// Product cubit
class ProductCubit extends Cubit<ProductState> {
  late final ProductRepository _productRepository;

  ProductCubit() : super(const ProductState()) {
    _productRepository = ProductRepository(sl<DatabaseService>());
  }

  // Load all products with pagination
  Future<void> loadProducts({int page = 1, bool resetPagination = true}) async {
    // Only set loading to true if we're not already loading (to avoid interfering with delete operations)
    final shouldSetLoading = !state.isLoading;
    if (shouldSetLoading) {
      emit(state.copyWith(isLoading: true, error: null));
    }

    try {
      print("state.currentPage = ${state.currentPage}");
      print(" state.itemsPerPage = ${state.itemsPerPage}");
      final products = await _productRepository.getAllProducts(
        state.currentPage,
        state.itemsPerPage,
      );
      print("products = $products");
      final filteredProducts = _applyFilters(products);

      // Calculate pagination
      final itemsPerPage = state.itemsPerPage;
      final totalItems = filteredProducts.length;
      final totalPages = (totalItems / itemsPerPage).ceil();
      final currentPage = page > totalPages ? (totalPages > 0 ? 1 : 0) : page;

      // Get products for current page
      // final startIndex = (currentPage - 1) * itemsPerPage;
      final pageProducts = filteredProducts;

      emit(
        state.copyWith(
          products: pageProducts,
          isLoading: false,
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Search products with pagination
  Future<void> searchProducts(String query) async {
    emit(state.copyWith(searchQuery: query));

    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    try {
      final products = await _productRepository.searchProducts(query);
      final filteredProducts = _applyFilters(products);

      // Calculate pagination
      final itemsPerPage = state.itemsPerPage;
      final totalItems = filteredProducts.length;
      final totalPages = (totalItems / itemsPerPage).ceil();

      // Get products for first page of search results
      final pageProducts = filteredProducts.take(itemsPerPage).toList();

      emit(
        state.copyWith(
          products: pageProducts,
          isLoading: false,
          currentPage: 1,
          totalPages: totalPages,
          totalItems: totalItems,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Set filter
  void setFilter(ProductFilter filter) {
    emit(state.copyWith(filter: filter, currentPage: 1));
    _applyCurrentFilters();
  }

  // Select product
  void selectProduct(Product product) {
    emit(state.copyWith(selectedProduct: product));
  }

  // Clear selection
  void clearSelection() {
    emit(
      state.copyWith(
        selectedProduct: null,
        isEditing: false,
        barcodeError: null,
        productNameError: null,
        sellPriceError: null,
        stockQuantityError: null,
      ),
    );
    print("state = $state");
  }

  // Start adding product
  void startAddProduct() {
    emit(
      state.copyWith(
        selectedProduct: null,
        isEditing: true,
        barcodeError: null,
        productNameError: null,
        sellPriceError: null,
        stockQuantityError: null,
      ),
    );
  }

  // Start editing product
  void startEditProduct(Product product) {
    emit(
      state.copyWith(
        selectedProduct: product,
        isEditing: true,
        barcodeError: null,
        productNameError: null,
        sellPriceError: null,
        stockQuantityError: null,
      ),
    );
  }

  // Validate form fields
  bool validateForm({
    required String barcode,
    required String productName,
    required String sellPriceText,
    required String stockQuantityText,
  }) {
    String? barcodeError;
    String? productNameError;
    String? sellPriceError;
    String? stockQuantityError;

    if (barcode.trim().isEmpty) {
      barcodeError = 'Barcode is required';
    }

    if (productName.trim().isEmpty) {
      productNameError = 'Product name is required';
    }

    final sellPrice = double.tryParse(sellPriceText);
    if (sellPriceText.trim().isEmpty) {
      sellPriceError = 'Sell price is required';
    } else if (sellPrice == null || sellPrice < 0) {
      sellPriceError = 'Invalid sell price';
    }

    final stockQuantity = int.tryParse(stockQuantityText);
    if (stockQuantityText.trim().isEmpty) {
      stockQuantityError = 'Stock quantity is required';
    } else if (stockQuantity == null) {
      stockQuantityError = 'Invalid stock quantity format';
    } else if (stockQuantity < 0) {
      stockQuantityError =
          'Stock quantity cannot be negative (found: $stockQuantity)';
    }

    emit(
      state.copyWith(
        barcodeError: barcodeError,
        productNameError: productNameError,
        sellPriceError: sellPriceError,
        stockQuantityError: stockQuantityError,
      ),
    );

    return barcodeError == null &&
        productNameError == null &&
        sellPriceError == null &&
        stockQuantityError == null;
  }

  // Clear form errors
  void clearFormErrors() {
    emit(
      state.copyWith(
        barcodeError: null,
        productNameError: null,
        sellPriceError: null,
        stockQuantityError: null,
      ),
    );
  }

  // Add product
  Future<void> addProduct(Map<String, dynamic> productData) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _productRepository.addProduct(
        barcode: productData['barcode'],
        productName: productData['productName'],
        description: productData['description'],
        categoryId: productData['categoryId'] ?? 1,
        supplierId: productData['supplierId'] ?? 1,
        unitTypeId: productData['unitTypeId'] ?? 1,
        costPrice: productData['costPrice'] ?? 0,
        sellPrice: productData['sellPrice'],
        stockQuantity: productData['stockQuantity'],
        reorderLevel: productData['reorderLevel'] ?? 10,
        isActive: productData['isActive'] ?? true,
      );

      await loadProducts();
      // Ensure loading is reset and clear selection after successful add
      emit(
        state.copyWith(
          isLoading: false,
          // selectedProduct: null,
          isEditing: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Update product
  Future<void> updateProduct(
    int productId,
    Map<String, dynamic> productData,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _productRepository.updateProduct(
        productId,
        barcode: productData['barcode'],
        productName: productData['productName'],
        description: productData['description'],
        categoryId: productData['categoryId'],
        supplierId: productData['supplierId'],
        unitTypeId: productData['unitTypeId'],
        costPrice: productData['costPrice'],
        sellPrice: productData['sellPrice'],
        stockQuantity: productData['stockQuantity'],
        reorderLevel: productData['reorderLevel'],
        isActive: productData['isActive'],
      );

      await loadProducts();
      // Ensure loading is reset and clear selection after successful update
      emit(
        state.copyWith(
          isLoading: false,
          selectedProduct: null,
          isEditing: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Delete product
  Future<void> deleteProduct(int productId) async {
    // Don't set loading to true to avoid blocking the UI during deletion
    emit(state.copyWith(error: null));

    try {
      await _productRepository.deactivateProduct(productId);

      // Clear selection if deleted product was selected
      final newSelectedProduct = state.selectedProduct?.productId == productId
          ? null
          : state.selectedProduct;

      // Remove the deleted product from the current list optimistically
      final updatedProducts = state.products
          .where((p) => p.productId != productId)
          .toList();

      // Update total items count
      final newTotalItems = state.totalItems - 1;
      final newTotalPages = (newTotalItems / state.itemsPerPage).ceil();

      // If current page is now empty and we're not on the first page, go to previous page
      int newCurrentPage = state.currentPage;
      if (updatedProducts.isEmpty &&
          state.currentPage > 1 &&
          state.currentPage > newTotalPages) {
        newCurrentPage = state.currentPage - 1;
      }

      // Emit new state immediately for better UX
      emit(
        state.copyWith(
          isLoading: false,
          selectedProduct: newSelectedProduct,
          products: updatedProducts,
          totalItems: newTotalItems,
          totalPages: newTotalPages > 0 ? newTotalPages : 1,
          currentPage: newCurrentPage,
        ),
      );

      // Then refresh from database to ensure consistency (but don't show loading)
      await loadProducts(page: newCurrentPage);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // Update product stock
  Future<void> updateProductStock(int productId, int newQuantity) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      await _productRepository.updateProductStock(productId, newQuantity);
      await loadProducts();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Apply current filters to products
  void _applyCurrentFilters() {
    // if (state.products.isEmpty) return;

    // If we have a search query, we don't need to re-apply filters
    if (state.searchQuery.isEmpty) {
      loadProducts();
    } else {
      // Apply filters to current search results
      final filteredProducts = _applyFilters(state.products);
      emit(state.copyWith(products: filteredProducts));
    }
  }

  // Apply filters to a list of products
  List<Product> _applyFilters(List<Product> products) {
    switch (state.filter) {
      case ProductFilter.inStock:
        return products.where((p) => !p.isLowStock && !p.isOutOfStock).toList();
      case ProductFilter.lowStock:
        return products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
      case ProductFilter.outOfStock:
        return products.where((p) => p.isOutOfStock).toList();
      case ProductFilter.all:
        return products;
    }
  }

  // Get filtered products for the current state
  List<Product> get filteredProducts {
    return _applyFilters(state.products);
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      return await _productRepository.getProductStatistics();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // Get all categories
  Future<List<Category>> getCategories() async {
    try {
      return await _productRepository.getAllCategories();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // Get all suppliers
  Future<List<Supplier>> getSuppliers() async {
    try {
      return await _productRepository.getAllSuppliers();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // Add category
  Future<void> addCategory(String categoryName) async {
    try {
      await _productRepository.addCategory(categoryName);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // Add supplier
  Future<void> addSupplier({
    required String companyName,
    String? contactName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      await _productRepository.addSupplier(
        companyName: companyName,
        contactName: contactName,
        phoneNumber: phoneNumber,
        address: address,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // Get all unit types
  Future<List<UnitType>> getUnitTypes() async {
    try {
      return await _productRepository.getAllUnitTypes();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  // === PAGINATION METHODS ===

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page < 1 || page > state.totalPages) return;

    emit(state.copyWith(currentPage: page));
    await _loadCurrentPageData();
  }

  // Go to next page
  Future<void> nextPage() async {
    if (state.currentPage < state.totalPages) {
      await goToPage(state.currentPage + 1);
    }
  }

  // Go to previous page
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      await goToPage(state.currentPage - 1);
    }
  }

  // Change items per page
  Future<void> changeItemsPerPage(int itemsPerPage) async {
    if (itemsPerPage <= 0) return;

    emit(
      state.copyWith(
        itemsPerPage: itemsPerPage,
        currentPage: 1, // Reset to first page when changing items per page
      ),
    );
    await loadProducts(page: 1);
  }

  // Load data for current page (used for pagination navigation)
  Future<void> _loadCurrentPageData() async {
    try {
      List<Product> allProducts;

      if (state.searchQuery.isNotEmpty) {
        allProducts = await _productRepository.searchProducts(
          state.searchQuery,
        );
      } else {
        allProducts = await _productRepository.getAllProducts(
          state.currentPage,
          state.itemsPerPage,
        );
      }

      final filteredProducts = _applyFilters(allProducts);

      // Calculate pagination
      final itemsPerPage = state.itemsPerPage;
      final totalItems = filteredProducts.length;
      final totalPages = (totalItems / itemsPerPage).ceil();

      // Get products for current page
      final startIndex = (state.currentPage - 1) * itemsPerPage;
      final pageProducts = filteredProducts
          .skip(startIndex)
          .take(itemsPerPage)
          .toList();

      emit(
        state.copyWith(
          products: pageProducts,
          totalPages: totalPages,
          totalItems: totalItems,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
