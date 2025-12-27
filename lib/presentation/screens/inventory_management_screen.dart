import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/product.dart';
import '../../data/logic/auth/auth_cubit.dart';
import '../../core/widgets/paginated_table.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late InventoryRepository _inventoryRepository;
  late AuthRepository _authRepository;

  // Pagination state for each tab
  int _currentPageAll = 1;
  int _currentPageLowStock = 1;
  int _currentPageOutOfStock = 1;
  int _currentPageSearch = 1;

  static const int _pageSize = 20;

  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  List<Product> _outOfStockProducts = [];
  List<Product> _searchResults = [];
  Map<String, int> _summary = {};

  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();

  // Pagination info
  int _totalAll = 0;
  int _totalLowStock = 0;
  int _totalOutOfStock = 0;
  int _totalSearch = 0;
  int _totalPagesAll = 0;
  int _totalPagesLowStock = 0;
  int _totalPagesOutOfStock = 0;
  int _totalPagesSearch = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _inventoryRepository = InventoryRepository();
    _authRepository = AuthRepository();
    _loadInventoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _inventoryRepository.getInventorySummary(),
        _loadAllProducts(page: 1),
        _loadLowStockProducts(page: 1),
        _loadOutOfStockProducts(page: 1),
      ]);

      setState(() {
        _summary = results[0] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading inventory: $e')));
      }
    }
  }

  Future<void> _loadAllProducts({int page = 1, bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _inventoryRepository.getAllProductsPaginated(
        page: page,
        limit: _pageSize,
      );

      setState(() {
        if (isLoadMore) {
          _allProducts.addAll(result.products);
        } else {
          _allProducts = result.products;
        }
        _totalAll = result.total;
        _totalPagesAll = result.totalPages;
        _currentPageAll = page;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  Future<void> _loadLowStockProducts({
    int page = 1,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _inventoryRepository.getLowStockProductsPaginated(
        page: page,
        limit: _pageSize,
      );

      setState(() {
        if (isLoadMore) {
          _lowStockProducts.addAll(result.products);
        } else {
          _lowStockProducts = result.products;
        }
        _totalLowStock = result.total;
        _totalPagesLowStock = result.totalPages;
        _currentPageLowStock = page;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading low stock products: $e')),
        );
      }
    }
  }

  Future<void> _loadOutOfStockProducts({
    int page = 1,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _inventoryRepository.getOutOfStockProductsPaginated(
        page: page,
        limit: _pageSize,
      );

      setState(() {
        if (isLoadMore) {
          _outOfStockProducts.addAll(result.products);
        } else {
          _outOfStockProducts = result.products;
        }
        _totalOutOfStock = result.total;
        _totalPagesOutOfStock = result.totalPages;
        _currentPageOutOfStock = page;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading out of stock products: $e')),
        );
      }
    }
  }

  Future<void> _searchProducts(
    String query, {
    int page = 1,
    bool isLoadMore = false,
  }) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      if (page == 1) _isLoading = true;
    });

    try {
      final result = await _inventoryRepository.searchProductsPaginated(
        query: query,
        page: page,
        limit: _pageSize,
      );

      setState(() {
        if (isLoadMore) {
          _searchResults.addAll(result.products);
        } else {
          _searchResults = result.products;
        }
        _totalSearch = result.total;
        _totalPagesSearch = result.totalPages;
        _currentPageSearch = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching products: $e')));
      }
    }
  }

  void _showStockAdjustmentDialog(Product product) {
    final quantityController = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock - ${product.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Adjustment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(quantityController.text);
              final reason = reasonController.text.trim();

              if (newQuantity == null || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final authState = context.read<AuthCubit>().state;
              final session = authState.whenOrNull(
                authenticated: (session) => session,
              );

              if (session != null) {
                final success = await _inventoryRepository.updateStockQuantity(
                  productId: product.productId,
                  newQuantity: newQuantity,
                  reason: reason,
                  userId: session.user.userId,
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock updated successfully')),
                  );
                  _refreshCurrentTab();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update stock')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStockHistory(Product product) async {
    final movements = await _inventoryRepository.getStockMovementHistory(
      product.productId,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock History - ${product.productName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: movements.isEmpty
              ? const Center(child: Text('No stock movements found'))
              : ListView.builder(
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    return ListTile(
                      leading: Icon(
                        movement.quantity < 0
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: movement.quantity < 0
                            ? Colors.red
                            : Colors.green,
                      ),
                      title: Text(movement.movementTypeDisplay),
                      subtitle: Text(
                        '${movement.username} - ${movement.notes ?? "No notes"}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            movement.formattedQuantity,
                            style: TextStyle(
                              color: movement.quantity < 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${movement.createdAt.day}/${movement.createdAt.month}/${movement.createdAt.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0: // Summary
        _loadInventoryData();
        break;
      case 1: // All Products
        _loadAllProducts(page: 1);
        break;
      case 2: // Low Stock
        _loadLowStockProducts(page: 1);
        break;
      case 3: // Out of Stock
        _loadOutOfStockProducts(page: 1);
        break;
    }
  }

  Widget _buildSummaryCards() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Products',
                    _summary['total_products']?.toString() ?? '0',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Active',
                    _summary['active_products']?.toString() ?? '0',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Low Stock',
                    _summary['low_stock']?.toString() ?? '0',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'Out of Stock',
                    _summary['out_of_stock']?.toString() ?? '0',
                    Icons.error,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.dashboard)),
            Tab(text: 'All Products', icon: Icon(Icons.inventory)),
            Tab(text: 'Low Stock', icon: Icon(Icons.warning)),
            Tab(text: 'Out of Stock', icon: Icon(Icons.error)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentTab,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResults.clear();
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _isSearching = false;
                      _searchResults.clear();
                    });
                  } else {
                    _searchProducts(value);
                  }
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildAllProductsTab(),
                _buildLowStockTab(),
                _buildOutOfStockTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _tabController.animateTo(2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_summary['low_stock'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Low Stock Items'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _tabController.animateTo(3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '${_summary['out_of_stock'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Out of Stock'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsTab() {
    final products = _isSearching ? _searchResults : _allProducts;
    final currentPage = _isSearching ? _currentPageSearch : _currentPageAll;
    final totalPages = _isSearching ? _totalPagesSearch : _totalPagesAll;
    final totalItems = _isSearching ? _totalSearch : _totalAll;

    if (_isLoading && currentPage == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name or barcode...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _searchResults.clear();
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                _searchProducts(value);
              } else {
                setState(() {
                  _isSearching = false;
                  _searchResults.clear();
                });
              }
            },
          ),
        ),
        Expanded(
          child: PaginatedTable<Product>(
            data: products,
            columns: [
              TableColumnConfig<Product>(
                headerKey: 'Barcode',
                headerText: 'Barcode',
                cellBuilder: (product, index) =>
                    Text(product.barcode, style: const TextStyle(fontSize: 12)),
                minWidth: 100,
              ),
              TableColumnConfig<Product>(
                headerKey: 'Product Name',
                headerText: 'Product Name',
                cellBuilder: (product, index) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (product.categoryName != null)
                      Text(
                        'Category: ${product.categoryName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
                minWidth: 200,
              ),
              TableColumnConfig<Product>(
                headerKey: 'Price',
                headerText: 'Price',
                cellBuilder: (product, index) => Text(
                  '${product.sellPrice}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                minWidth: 80,
                alignment: Alignment.center,
              ),
              TableColumnConfig<Product>(
                headerKey: 'Stock',
                headerText: 'Stock',
                cellBuilder: (product, index) => Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: product.isOutOfStock
                          ? Colors.red
                          : product.isLowStock
                          ? Colors.orange
                          : Colors.green,
                      child: Text(
                        '${product.stockQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.isOutOfStock
                          ? 'Out of Stock'
                          : product.isLowStock
                          ? 'Low Stock'
                          : 'In Stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: product.isOutOfStock
                            ? Colors.red
                            : product.isLowStock
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                minWidth: 120,
              ),
            ],
            actions: [
              ActionConfig<Product>(
                icon: Icons.history,
                tooltipText: 'Stock History',
                onPressed: (product) => _showStockHistory(product),
                color: Colors.blue,
              ),
              ActionConfig<Product>(
                icon: Icons.edit,
                tooltipText: 'Adjust Stock',
                onPressed: (product) => _showStockAdjustmentDialog(product),
                color: Colors.green,
              ),
            ],
            pagination: PaginationConfig(
              currentPage: currentPage,
              totalPages: totalPages,
              totalItems: totalItems,
              itemsPerPage: _pageSize,
              onPageChanged: (page) {
                if (_isSearching) {
                  _searchProducts(_searchController.text, page: page);
                } else {
                  _loadAllProducts(page: page);
                }
              },
            ),
            emptyMessage: 'No products found',
            emptyIcon: const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockTab() {
    if (_isLoading && _currentPageLowStock == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    return PaginatedTable<Product>(
      data: _lowStockProducts,
      columns: [
        TableColumnConfig<Product>(
          headerKey: 'Barcode',
          headerText: 'Barcode',
          cellBuilder: (product, index) =>
              Text(product.barcode, style: const TextStyle(fontSize: 12)),
          minWidth: 100,
        ),
        TableColumnConfig<Product>(
          headerKey: 'Product Name',
          headerText: 'Product Name',
          cellBuilder: (product, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.productName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (product.categoryName != null)
                Text(
                  'Category: ${product.categoryName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
          ),
          minWidth: 200,
        ),
        TableColumnConfig<Product>(
          headerKey: 'Price',
          headerText: 'Price',
          cellBuilder: (product, index) => Text(
            '${product.sellPrice}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          minWidth: 80,
          alignment: Alignment.center,
        ),
        TableColumnConfig<Product>(
          headerKey: 'Stock',
          headerText: 'Stock',
          cellBuilder: (product, index) => Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  '${product.stockQuantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Low Stock',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          minWidth: 120,
        ),
      ],
      actions: [
        ActionConfig<Product>(
          icon: Icons.history,
          tooltipText: 'Stock History',
          onPressed: (product) => _showStockHistory(product),
          color: Colors.blue,
        ),
        ActionConfig<Product>(
          icon: Icons.edit,
          tooltipText: 'Adjust Stock',
          onPressed: (product) => _showStockAdjustmentDialog(product),
          color: Colors.green,
        ),
      ],
      pagination: PaginationConfig(
        currentPage: _currentPageLowStock,
        totalPages: _totalPagesLowStock,
        totalItems: _totalLowStock,
        itemsPerPage: _pageSize,
        onPageChanged: (page) {
          _loadLowStockProducts(page: page);
        },
      ),
      emptyMessage: 'No low stock products found',
      emptyIcon: const Icon(
        Icons.warning,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildOutOfStockTab() {
    if (_isLoading && _currentPageOutOfStock == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    return PaginatedTable<Product>(
      data: _outOfStockProducts,
      columns: [
        TableColumnConfig<Product>(
          headerKey: 'Barcode',
          headerText: 'Barcode',
          cellBuilder: (product, index) =>
              Text(product.barcode, style: const TextStyle(fontSize: 12)),
          minWidth: 100,
        ),
        TableColumnConfig<Product>(
          headerKey: 'Product Name',
          headerText: 'Product Name',
          cellBuilder: (product, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.productName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (product.categoryName != null)
                Text(
                  'Category: ${product.categoryName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
          ),
          minWidth: 200,
        ),
        TableColumnConfig<Product>(
          headerKey: 'Price',
          headerText: 'Price',
          cellBuilder: (product, index) => Text(
            '${product.sellPrice}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          minWidth: 80,
          alignment: Alignment.center,
        ),
        TableColumnConfig<Product>(
          headerKey: 'Stock',
          headerText: 'Stock',
          cellBuilder: (product, index) => Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red,
                child: Text(
                  '${product.stockQuantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Out of Stock',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          minWidth: 120,
        ),
      ],
      actions: [
        ActionConfig<Product>(
          icon: Icons.history,
          tooltipText: 'Stock History',
          onPressed: (product) => _showStockHistory(product),
          color: Colors.blue,
        ),
        ActionConfig<Product>(
          icon: Icons.edit,
          tooltipText: 'Adjust Stock',
          onPressed: (product) => _showStockAdjustmentDialog(product),
          color: Colors.green,
        ),
      ],
      pagination: PaginationConfig(
        currentPage: _currentPageOutOfStock,
        totalPages: _totalPagesOutOfStock,
        totalItems: _totalOutOfStock,
        itemsPerPage: _pageSize,
        onPageChanged: (page) {
          _loadOutOfStockProducts(page: page);
        },
      ),
      emptyMessage: 'No out of stock products found',
      emptyIcon: const Icon(
        Icons.error,
        size: 64,
        color: Colors.grey,
      ),
    );
  }
}
