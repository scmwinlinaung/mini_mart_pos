import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/product.dart';
import '../../data/logic/auth/auth_cubit.dart';

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

  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  List<Product> _outOfStockProducts = [];
  Map<String, int> _summary = {};

  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
        _inventoryRepository.getAllProducts(),
        _inventoryRepository.getLowStockProducts(),
        _inventoryRepository.getOutOfStockProducts(),
        _inventoryRepository.getInventorySummary(),
      ]);

      setState(() {
        _allProducts = results[0] as List<Product>;
        _lowStockProducts = results[1] as List<Product>;
        _outOfStockProducts = results[2] as List<Product>;
        _summary = results[3] as Map<String, int>;
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

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await _inventoryRepository.searchProducts(query);
      setState(() {
        _allProducts = results;
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
                  _loadInventoryData();
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

  Widget _buildProductList(List<Product> products) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: product.isOutOfStock
                  ? Colors.red
                  : product.isLowStock
                  ? Colors.orange
                  : Colors.green,
              child: Text(
                '${product.stockQuantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(product.productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Barcode: ${product.barcode}'),
                if (product.categoryName != null)
                  Text('Category: ${product.categoryName}'),
                Text('Price: ${product.sellPrice}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => _showStockHistory(product),
                  tooltip: 'Stock History',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showStockAdjustmentDialog(product),
                  tooltip: 'Adjust Stock',
                ),
              ],
            ),
          ),
        );
      },
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
            onPressed: _loadInventoryData,
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
                      });
                      _loadInventoryData();
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _isSearching = false;
                    });
                    _loadInventoryData();
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
                _buildProductsTab(_allProducts, isSearchable: true),
                _buildProductsTab(_lowStockProducts),
                _buildProductsTab(_outOfStockProducts),
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

  Widget _buildProductsTab(
    List<Product> products, {
    bool isSearchable = false,
  }) {
    if (isSearchable && !_isSearching) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _searchProducts(value);
                }
              },
            ),
          ),
          Expanded(child: _buildProductList(products)),
        ],
      );
    }
    return _buildProductList(products);
  }
}
