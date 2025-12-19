import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/purchases.dart';
import '../../data/models/product.dart';
import '../widgets/barcode_scanner_widget.dart';

class AddPurchaseDialog extends StatefulWidget {
  const AddPurchaseDialog({Key? key}) : super(key: key);

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _purchaseDateController = TextEditingController(
    text:
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
  );

  int? _selectedSupplierId;
  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  List<PurchaseItem> _purchaseItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLookupData();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  Future<void> _loadLookupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load actual data from repositories
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data for now
      setState(() {
        _suppliers = [
          Supplier(
            supplierId: 1,
            companyName: 'Coca-Cola Company',
            contactName: 'John Smith',
            phoneNumber: '+959123456789',
            address: '123 Business St, Yangon',
          ),
          Supplier(
            supplierId: 2,
            companyName: 'Snack Foods Inc',
            contactName: 'Jane Doe',
            phoneNumber: '+959987654321',
            address: '456 Industrial Ave, Mandalay',
          ),
        ];

        _products = [
          Product.fromMap({
            'product_id': 1,
            'category_id': 1,
            'supplier_id': 1,
            'unit_type_id': 1,
            'barcode': '1234567890123',
            'product_name': 'Coca Cola 500ml',
            'description': 'Refreshing cola drink',
            'cost_price': 50,
            'sell_price': 75,
            'stock_quantity': 100,
            'reorder_level': 20,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }),
          Product.fromMap({
            'product_id': 2,
            'category_id': 1,
            'supplier_id': 1,
            'unit_type_id': 1,
            'barcode': '1234567890124',
            'product_name': 'Sprite 500ml',
            'description': 'Lemon-lime soda',
            'cost_price': 45,
            'sell_price': 70,
            'stock_quantity': 80,
            'reorder_level': 15,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  void _addPurchaseItem() {
    showDialog(
      context: context,
      builder: (context) => AddPurchaseItemDialog(
        products: _products,
        onAdd: (item) {
          setState(() {
            _purchaseItems.add(item);
          });
        },
      ),
    );
  }

  void _removePurchaseItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  int get _totalAmount {
    return _purchaseItems.fold<int>(0, (sum, item) => sum + item.total);
  }

  void _savePurchase() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final purchaseData = {
      'supplier_id': _selectedSupplierId,
      'supplier_invoice_no': _invoiceController.text.trim().isEmpty
          ? null
          : _invoiceController.text.trim(),
      'total_amount': _totalAmount,
      'status': PurchaseStatus.pending.name,
      'purchase_date': DateTime.now().toIso8601String(),
    };

    final itemsData = _purchaseItems.map((item) {
      return {
        'product_id': item.productId,
        'quantity': item.quantity,
        'buy_price': item.buyPrice,
        'expiry_date': item.expiryDate?.toIso8601String(),
      };
    }).toList();

    Navigator.of(
      context,
    ).pop({'purchaseData': purchaseData, 'itemsData': itemsData});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.indigo[700]),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Purchase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedSupplierId,
                              decoration: const InputDecoration(
                                labelText: 'Supplier *',
                                border: OutlineInputBorder(),
                              ),
                              items: _suppliers.map((supplier) {
                                return DropdownMenuItem<int>(
                                  value: supplier.supplierId,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      supplier.companyName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupplierId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a supplier';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceController,
                              decoration: const InputDecoration(
                                labelText: 'Supplier Invoice #',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Purchase Items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Purchase Items',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addPurchaseItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Items List
                      Expanded(
                        child: _purchaseItems.isEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No items added yet',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Click "Add Item" to start adding products',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Product',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Quantity',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Unit Price',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'Total',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 40,
                                            child: Text(
                                              '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Items
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _purchaseItems.length,
                                        itemBuilder: (context, index) {
                                          final item = _purchaseItems[index];
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.grey[200]!,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item.productName ??
                                                            'Unknown Product',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (item.barcode !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          'Barcode: ${item.barcode}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                      if (item.expiryDate !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          'Expiry: ${item.expiryDisplay}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                item.isExpired
                                                                ? Colors.red
                                                                : item.isExpiringSoon
                                                                ? Colors.orange
                                                                : Colors
                                                                      .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    item.quantity.toString(),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    item.formattedBuyPrice,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    item.formattedTotal,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  child: IconButton(
                                                    onPressed: () =>
                                                        _removePurchaseItem(
                                                          index,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      size: 16,
                                                      color: Colors.red,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 24,
                                                          minHeight: 24,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${(_totalAmount / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _savePurchase,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save Purchase'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddPurchaseItemDialog extends StatefulWidget {
  final List<Product> products;
  final Function(PurchaseItem) onAdd;

  const AddPurchaseItemDialog({
    Key? key,
    required this.products,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<AddPurchaseItemDialog> createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<AddPurchaseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _expiryController = TextEditingController();

  Product? _selectedProduct;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
        _expiryController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    final item = PurchaseItem(
      itemId: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      purchaseId: 0, // Will be set when purchase is saved
      productId: _selectedProduct!.productId,
      productName: _selectedProduct!.productName,
      barcode: _selectedProduct!.barcode,
      quantity: int.parse(_quantityController.text),
      buyPrice: (double.parse(_priceController.text) * 100).toInt(),
      expiryDate: _expiryDate,
    );

    widget.onAdd(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Purchase Item',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Product *',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.products.map((product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              '${product.productName} (${product.barcode})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (product) {
                        setState(() {
                          _selectedProduct = product;
                          // Pre-fill cost price if available
                          if (product != null) {
                            _priceController.text = product.costPrice
                                .toString();
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a product';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null) {
                                return 'Invalid quantity format';
                              }
                              if (quantity <= 0) {
                                return 'Quantity must be greater than 0 (found: $quantity)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Unit Price (\$) *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter unit price';
                              }
                              final price = double.tryParse(value);
                              if (price == null) {
                                return 'Invalid price format';
                              }
                              if (price <= 0) {
                                return 'Price must be greater than 0 (found: $price)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: _selectExpiryDate,
                          icon: const Icon(Icons.calendar_today),
                        ),
                      ),
                      readOnly: true,
                      onTap: _selectExpiryDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addItem,
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
