import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/product/product_cubit.dart';
import '../../data/models/product.dart';
import '../../core/service_locator.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/paginated_table.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../widgets/language_selector.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  // Form controllers
  late TextEditingController _barcodeController;
  late TextEditingController _productNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _reorderLevelController;

  // Dropdown values
  int? _selectedCategoryId;
  int? _selectedSupplierId;
  int? _selectedUnitTypeId = 1; // Default to PCS

  // Data lists
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  List<UnitType> _unitTypes = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadLookupData();
  }

  void _initializeControllers() {
    _barcodeController = TextEditingController();
    _productNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _costPriceController = TextEditingController();
    _sellPriceController = TextEditingController();
    _stockQuantityController = TextEditingController();
    _reorderLevelController = TextEditingController();
  }

  void _populateFormControllers(Product product) {
    _barcodeController.text = product.barcode;
    _productNameController.text = product.productName;
    _descriptionController.text = product.description ?? '';
    _costPriceController.text = product.costPrice.toString();
    _sellPriceController.text = product.sellPrice.toString();
    _stockQuantityController.text = product.stockQuantity.toString();
    _reorderLevelController.text = product.reorderLevel.toString();
    _selectedCategoryId = product.categoryId;
    _selectedSupplierId = product.supplierId;
    _selectedUnitTypeId = product.unitTypeId;

    // Update UI to reflect dropdown changes
    if (mounted) {
      setState(() {});
    }
  }

  void _clearFormControllers() {
    _barcodeController.clear();
    _productNameController.clear();
    _descriptionController.clear();
    _costPriceController.clear();
    _sellPriceController.clear();
    _stockQuantityController.clear();
    _reorderLevelController.clear();
    _selectedCategoryId = null;
    _selectedSupplierId = null;
    _selectedUnitTypeId = 1; // Reset to default

    // Update UI to reflect dropdown changes
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLookupData() async {
    try {
      final cubit = context.read<ProductCubit>();

      // Load categories, suppliers, and unit types in parallel
      final categoriesFuture = cubit.getCategories();
      final suppliersFuture = cubit.getSuppliers();
      final unitTypesFuture = cubit.getUnitTypes();

      final categories = await categoriesFuture;
      final suppliers = await suppliersFuture;
      final unitTypes = await unitTypesFuture;
      print("suppliers = $suppliers");
      setState(() {
        _categories = categories;
        _suppliers = suppliers;
        _unitTypes = unitTypes;
      });
    } catch (e) {
      print('Error loading lookup data: $e');
      // Fallback to basic data if loading fails
      setState(() {
        _categories = [
          Category(categoryId: 1, categoryName: 'အချိုရည်များ'),
          Category(categoryId: 2, categoryName: 'စားသောက်ကုန်ပစ္စည်းများ'),
          Category(categoryId: 3, categoryName: 'အိမ်သုံးပစ္စည်းများ'),
        ];
        _suppliers = [
          Supplier(
            supplierId: 1,
            companyName: 'ကုန်ပစ္စည်းကုန်းကမ်းရောင်းချ ကုမ္ပဏီ',
          ),
          Supplier(supplierId: 2, companyName: 'အခြေခံပစ္စည်းများ ကုမ္ပဏီ'),
        ];
        _unitTypes = [
          UnitType(
            unitId: 1,
            unitCode: 'PCS',
            unitName: 'အရေအတွက်',
            createdAt: DateTime.now(),
          ),
          UnitType(
            unitId: 2,
            unitCode: 'KG',
            unitName: 'ကီလိုဂရမ်',
            createdAt: DateTime.now(),
          ),
          UnitType(
            unitId: 3,
            unitCode: 'G',
            unitName: 'ဂရမ်',
            createdAt: DateTime.now(),
          ),
          UnitType(
            unitId: 4,
            unitCode: 'L',
            unitName: 'လီတာ',
            createdAt: DateTime.now(),
          ),
          UnitType(
            unitId: 5,
            unitCode: 'ML',
            unitName: 'မီလီလီတာ',
            createdAt: DateTime.now(),
          ),
        ];
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _stockQuantityController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProductCubit>()..loadProducts(),
      child: DesktopScaffold(
        appBar: DesktopAppBar(
          title: context.getString(AppStrings.productManagement),
          showBackButton: true,
        ),
        body: Row(
          children: [
            // Product List (Left Side)
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSearchBar(context),
                    _buildFilterTabs(context),
                    Expanded(child: _buildProductList(context)),
                  ],
                ),
              ),
            ),

            // Product Form (Right Side)
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                child: _buildProductForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: context.getString(AppStrings.searchProducts),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                context.read<ProductCubit>().searchProducts(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              context.read<ProductCubit>().refreshProducts();
            },
            icon: const Icon(Icons.refresh),
            tooltip: context.getString(AppStrings.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          return Row(
            children: [
              _buildFilterChip(
                context,
                context.getString(AppStrings.all),
                state.filter == ProductFilter.all,
                () => context.read<ProductCubit>().setFilter(ProductFilter.all),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                context.getString(AppStrings.inStock),
                state.filter == ProductFilter.inStock,
                () => context.read<ProductCubit>().setFilter(
                  ProductFilter.inStock,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                context.getString(AppStrings.lowStock),
                state.filter == ProductFilter.lowStock,
                () => context.read<ProductCubit>().setFilter(
                  ProductFilter.lowStock,
                ),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                context.getString(AppStrings.outOfStock),
                state.filter == ProductFilter.outOfStock,
                () => context.read<ProductCubit>().setFilter(
                  ProductFilter.outOfStock,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildProductList(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return state.when(
          initial: () =>
              Center(child: Text(context.getString(AppStrings.selectProduct))),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (products, selectedProduct) {
            return PaginatedTable<Product>(
              data: products,
              columns: [
                TableColumnConfig<Product>(
                  headerKey: AppStrings.barcode,
                  cellBuilder: (product, index) => Text(
                    product.barcode,
                    style: const TextStyle(fontSize: 12),
                  ),
                  minWidth: 30,
                ),
                TableColumnConfig<Product>(
                  headerKey: AppStrings.productName,
                  cellBuilder: (product, index) => Text(product.productName),
                  // fit: FlexFit.loose,
                  minWidth: 40,
                ),
                TableColumnConfig<Product>(
                  headerKey: AppStrings.stockQuantity,
                  cellBuilder: (product, index) => Text(
                    '${product.stockQuantity}',
                    style: TextStyle(
                      color: product.isOutOfStock
                          ? Colors.red
                          : product.isLowStock
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  minWidth: 40,
                ),
                TableColumnConfig<Product>(
                  headerKey: AppStrings.price,
                  cellBuilder: (product, index) =>
                      Text(product.sellPrice.toString()),
                  minWidth: 40,
                ),
                TableColumnConfig<Product>(
                  headerKey: AppStrings.status,
                  cellBuilder: (product, index) => _buildStatusChip(product),
                  minWidth: 40,
                ),
              ],
              actions: [
                ActionConfig<Product>(
                  icon: Icons.edit,
                  tooltipKey: AppStrings.edit,
                  onPressed: (product) {
                    context.read<ProductCubit>().startEditProduct(product);
                  },
                ),
                ActionConfig<Product>(
                  icon: Icons.delete,
                  tooltipKey: AppStrings.delete,
                  color: Colors.red,
                  onPressed: (product) {
                    _showDeleteConfirmDialog(context, product);
                  },
                ),
              ],
              pagination: PaginationConfig(
                currentPage: state.currentPage,
                totalPages: state.totalPages,
                totalItems: state.totalItems,
                itemsPerPage: state.itemsPerPage,
                onPageChanged: (page) {
                  context.read<ProductCubit>().goToPage(page);
                },
                onItemsPerPageChanged: (itemsPerPage) {
                  context.read<ProductCubit>().changeItemsPerPage(itemsPerPage);
                },
              ),
              emptyMessageKey: AppStrings.noProductsFound,
              emptyIcon: const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey,
              ),
              onRowTap: (product) {
                context.read<ProductCubit>().selectProduct(product);
              },
            );
          },
          error: (message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  context.getString(AppStrings.error),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<ProductCubit>().refreshProducts(),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.getString(AppStrings.retry)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(Product product) {
    Color color;
    String textKey;

    if (product.isOutOfStock) {
      color = Colors.red;
      textKey = AppStrings.outOfStock;
    } else if (product.isLowStock) {
      color = Colors.orange;
      textKey = AppStrings.lowStock;
    } else {
      color = Colors.green;
      textKey = AppStrings.inStock;
    }

    return Builder(
      builder: (context) {
        return Chip(
          label: Text(
            context.getString(textKey),
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        );
      },
    );
  }

  Widget _buildProductForm(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        // Show loading overlay for main operations
        if (state.isLoading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state for main operations
        if (state.error != null && state.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                Text(
                  state.error!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<ProductCubit>().refreshProducts(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show form content (either empty form or with selected product)
        if (state.selectedProduct != null || state.isEditing) {
          return _buildProductFormContent(context, state.selectedProduct);
        } else {
          return _buildEmptyForm(context);
        }
      },
    );
  }

  Widget _buildEmptyForm(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.isEditing ? Icons.edit : Icons.add_circle_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                state.isEditing
                    ? 'Fill in the product details below'
                    : 'Select a product to edit or add a new one',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (!state.isEditing) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _clearFormControllers();
                    context.read<ProductCubit>().startAddProduct();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Product'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductFormContent(BuildContext context, Product? product) {
    final cubit = context.read<ProductCubit>();
    final isEditingProduct =
        product != null; // true if editing existing product
    print("isEditingProduct = $isEditingProduct");
    print("product = $product");
    // Update form controllers when product changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (product != null &&
          _productNameController.text != product.productName) {
        _populateFormControllers(product);
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditingProduct ? 'Edit Product' : 'Add Product',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  print('🔘 Close button pressed');
                  // Always allow closing, even during loading
                  _clearFormControllers();
                  cubit.clearSelection();
                  print('✅ Close button action completed');
                },
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      // Barcode field with scanner button
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barcode *',
                                border: const OutlineInputBorder(),
                                errorText: state.barcodeError,
                                suffixIcon: IconButton(
                                  onPressed: () => _showBarcodeScanner(context),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  tooltip: 'Scan Barcode',
                                ),
                              ),
                              onChanged: (value) {
                                // Clear error when user starts typing
                                if (state.barcodeError != null) {
                                  cubit.clearFormErrors();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name *',
                          border: const OutlineInputBorder(),
                          errorText: state.productNameError,
                        ),
                        onChanged: (value) {
                          if (state.productNameError != null) {
                            cubit.clearFormErrors();
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Dropdown fields
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.categoryId,
                            child: Text(
                              category.categoryName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedSupplierId,
                        decoration: const InputDecoration(
                          labelText: 'Supplier *',
                          border: OutlineInputBorder(),
                        ),
                        items: _suppliers.map((supplier) {
                          return DropdownMenuItem<int>(
                            value: supplier.supplierId,
                            child: Text(
                              supplier.companyName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        value: _selectedUnitTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Unit Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: _unitTypes.map((unitType) {
                          return DropdownMenuItem<int>(
                            value: unitType.unitId,
                            child: Text(
                              '${unitType.unitName} (${unitType.unitCode})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitTypeId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Cost Price (\$)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sellPriceController,
                              decoration: InputDecoration(
                                labelText: 'Sell Price (\$) *',
                                border: const OutlineInputBorder(),
                                errorText: state.sellPriceError,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (value) {
                                if (state.sellPriceError != null) {
                                  cubit.clearFormErrors();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockQuantityController,
                              decoration: InputDecoration(
                                labelText: 'Stock Quantity *',
                                border: const OutlineInputBorder(),
                                errorText: state.stockQuantityError,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (state.stockQuantityError != null) {
                                  cubit.clearFormErrors();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _reorderLevelController,
                              decoration: const InputDecoration(
                                labelText: 'Reorder Level',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () =>
                                        _saveProduct(context, isEditingProduct),
                              child: state.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(isEditingProduct ? 'Update' : 'Add'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Clear form controllers
                                _clearFormControllers();

                                // Always cancel editing and return to view mode
                                cubit.clearSelection();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBarcodeScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWidget(
          onBarcodeDetected: (barcode) {
            _barcodeController.text = barcode;
            context.read<ProductCubit>().clearFormErrors();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _saveProduct(BuildContext context, bool isEditingProduct) async {
    final cubit = context.read<ProductCubit>();

    // Validate form
    final isValid = cubit.validateForm(
      barcode: _barcodeController.text,
      productName: _productNameController.text,
      sellPriceText: _sellPriceController.text,
      stockQuantityText: _stockQuantityController.text,
    );

    if (!isValid) {
      return;
    }

    // Validate dropdown selections
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    if (_selectedUnitTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit type')),
      );
      return;
    }

    final productData = {
      'barcode': _barcodeController.text.trim(),
      'productName': _productNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'costPrice': int.tryParse(_costPriceController.text) ?? 0,
      'sellPrice': int.tryParse(_sellPriceController.text) ?? 0,
      'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 0,
      'reorderLevel': int.tryParse(_reorderLevelController.text) ?? 10,
      'categoryId': _selectedCategoryId!,
      'supplierId': _selectedSupplierId!,
      'unitTypeId': _selectedUnitTypeId!,
    };

    try {
      if (isEditingProduct && cubit.state.selectedProduct != null) {
        await cubit.updateProduct(
          cubit.state.selectedProduct!.productId,
          productData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }
      } else {
        await cubit.addProduct(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
        }
      }
      // cubit.clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${product.productName}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (mounted) {
                final cubit = context.read<ProductCubit>();
                await cubit.deleteProduct(product.productId);
                // Don't call loadProducts() here as it's already called in deleteProduct()
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, ProductState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: state.currentPage > 1
                ? () => context.read<ProductCubit>().previousPage()
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
          ),

          // Page numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageNumbers(context, state),
              ),
            ),
          ),

          // Next button
          IconButton(
            onPressed: state.currentPage < state.totalPages
                ? () => context.read<ProductCubit>().nextPage()
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context, ProductState state) {
    final List<Widget> pageNumbers = [];
    final currentPage = state.currentPage;
    final totalPages = state.totalPages;

    // Show maximum 5 page numbers at a time
    int startPage = math.max(1, currentPage - 2);
    int endPage = math.min(totalPages, startPage + 4);

    // Adjust start page if we're near the end
    if (endPage - startPage < 4) {
      startPage = math.max(1, endPage - 4);
    }

    // Show first page if not in range
    if (startPage > 1) {
      pageNumbers.add(_buildPageButton(context, 1, state));
      if (startPage > 2) {
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(Text('...', style: TextStyle(color: Colors.grey[600])));
        pageNumbers.add(const SizedBox(width: 8));
      }
    }

    // Show page numbers in range
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageButton(context, i, state));
      if (i < endPage) {
        pageNumbers.add(const SizedBox(width: 4));
      }
    }

    // Show last page if not in range
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(Text('...', style: TextStyle(color: Colors.grey[600])));
        pageNumbers.add(const SizedBox(width: 8));
      }
      pageNumbers.add(_buildPageButton(context, totalPages, state));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(
    BuildContext context,
    int pageNumber,
    ProductState state,
  ) {
    final isSelected = pageNumber == state.currentPage;

    return InkWell(
      onTap: () => context.read<ProductCubit>().goToPage(pageNumber),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          pageNumber.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
