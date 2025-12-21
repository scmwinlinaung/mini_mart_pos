import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/cart/cart_cubit.dart';
import '../../data/logic/scanner/scanner_cubit.dart';
import '../../data/logic/auth/auth_cubit.dart';
import '../../data/models/product.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../../core/widgets/paginated_table.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _scanCtrl = TextEditingController();
  final FocusNode _scanFocus = FocusNode();
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    // Keep focus on scan input
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scanFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: 'POS Terminal - Sales',
        showBackButton: true,
      ),
      body: MultiBlocListener(
        listeners: [
          // Listen for Scan Results
          BlocListener<ScannerCubit, ScannerState>(
            listener: (context, state) {
              if (state is ScannerSuccess) {
                // If product found, add to cart automatically
                context.read<CartCubit>().addProduct(state.product);
                _scanCtrl.clear();
                _scanFocus.requestFocus();
              } else if (state is ScannerFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
                _scanCtrl.clear();
                _scanFocus.requestFocus();
              }
            },
          ),
          // Listen for Cart Checkout Status
          BlocListener<CartCubit, CartState>(
            listener: (context, state) {
              if (state.status == CartStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Transaction Saved! Stock Updated."),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state.status == CartStatus.failure) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Error"),
                    content: Text(
                      state.errorMessage ?? "Unknown error occurred",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
        child: Row(
          children: [
            // LEFT: Cart Items - takes 2/3 of the space
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: _buildCartList(),
              ),
            ),

            // RIGHT: Controls - takes 1/3 of the space
            Expanded(
              flex: 1,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: _buildControls(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 8),
                  Text(
                    'Shopping Cart (${state.itemCount} items)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (state.items.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        context.read<CartCubit>().clearCart();
                        setState(() {
                          _currentPage =
                              1; // Reset pagination when clearing cart
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            // Cart Items
            Expanded(
              child: state.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Cart is Empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Scan a barcode to add products',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: PaginatedTable<CartItem>(
                        data: _getPaginatedItems(state.items),
                        columns: [
                          TableColumnConfig<CartItem>(
                            headerKey: 'Qty',
                            width: 60,
                            isFixed: true,
                            alignment: Alignment.center,
                            cellBuilder: (item, index) => CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 16,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          TableColumnConfig<CartItem>(
                            headerKey: 'Product Name',
                            cellBuilder: (item, index) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.product.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Barcode: ${item.product.barcode}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TableColumnConfig<CartItem>(
                            headerKey: 'Price',
                            width: 150,
                            isFixed: true,
                            alignment: Alignment.center,
                            cellBuilder: (item, index) => Text(
                              item.formattedUnitPrice,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TableColumnConfig<CartItem>(
                            headerKey: 'Total',
                            width: 150,
                            isFixed: true,
                            alignment: Alignment.center,
                            cellBuilder: (item, index) => Text(
                              item.formattedTotal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        actions: [
                          ActionConfig<CartItem>(
                            icon: Icons.remove_circle_outline,
                            tooltipText: 'Decrease quantity',
                            onPressed: (item) =>
                                context.read<CartCubit>().updateQuantity(
                                  item.product.productId,
                                  item.quantity - 1,
                                ),
                          ),
                          ActionConfig<CartItem>(
                            icon: Icons.add_circle_outline,
                            tooltipText: 'Increase quantity',
                            onPressed: (item) =>
                                context.read<CartCubit>().updateQuantity(
                                  item.product.productId,
                                  item.quantity + 1,
                                ),
                          ),
                          ActionConfig<CartItem>(
                            icon: Icons.delete_outline,
                            tooltipText: 'Remove item',
                            color: Colors.red,
                            onPressed: (item) => context
                                .read<CartCubit>()
                                .removeItem(item.product.productId),
                          ),
                        ],
                        pagination: PaginationConfig(
                          currentPage: _currentPage,
                          totalPages:
                              (state.items.length + _itemsPerPage - 1) ~/
                              _itemsPerPage,
                          totalItems: state.items.length,
                          itemsPerPage: _itemsPerPage,
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          onItemsPerPageChanged: (itemsPerPage) {
                            setState(() {
                              _itemsPerPage = itemsPerPage;
                              _currentPage =
                                  1; // Reset to first page when changing items per page
                            });
                          },
                          availableItemsPerPage: [5, 10, 20, 50],
                        ),
                        emptyMessage: 'No items in cart',
                        emptyIcon: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        rowHeight: 80,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scanner Input Section
          Text(
            'Add Product',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _scanCtrl,
            focusNode: _scanFocus,
            decoration: InputDecoration(
              labelText: "Scan or Enter Barcode",
              hintText: "Enter barcode manually",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _scanCtrl.clear();
                  _scanFocus.requestFocus();
                },
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                context.read<ScannerCubit>().scanBarcode(val.trim());
              }
            },
            autofocus: true,
          ),

          const SizedBox(height: 20),

          // Quick Actions
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Show product search dialog
            },
            icon: const Icon(Icons.search),
            label: const Text('Search Products'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const Spacer(),

          // Summary Section
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              return Column(
                children: [
                  const Divider(),
                  _buildSummaryRow('Subtotal', state.grandTotal, context),
                  _buildSummaryRow('Tax (0%)', 0, context),
                  const Divider(thickness: 2),
                  _buildSummaryRow(
                    'TOTAL',
                    state.grandTotal,
                    context,
                    isTotal: true,
                  ),
                  const SizedBox(height: 20),

                  // Payment Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: state.status == CartStatus.processing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.attach_money),
                          label: Text(
                            state.items.isEmpty
                                ? "ADD ITEMS FIRST"
                                : "CASH PAYMENT",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.items.isEmpty
                                ? Colors.grey.shade400
                                : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              state.status == CartStatus.processing ||
                                  state.items.isEmpty
                              ? null
                              : () {
                                  print('CASH button pressed');
                                  _handleCheckout(context, 'CASH');
                                },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.credit_card),
                          label: Text(
                            state.items.isEmpty
                                ? "ADD ITEMS FIRST"
                                : "CARD PAYMENT",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.items.isEmpty
                                ? Colors.grey.shade400
                                : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              state.status == CartStatus.processing ||
                                  state.items.isEmpty
                              ? null
                              : () {
                                  print('CARD button pressed');
                                  _handleCheckout(context, 'CARD');
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    int amount,
    BuildContext context, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$ $amount',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  List<CartItem> _getPaginatedItems(List<CartItem> allItems) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= allItems.length) {
      return [];
    }

    return allItems.sublist(
      startIndex,
      endIndex > allItems.length ? allItems.length : endIndex,
    );
  }

  void _handleCheckout(BuildContext context, String paymentMethod) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.whenOrNull(
      authenticated: (session) => session.user.userId,
    );

    if (userId != null) {
      context.read<CartCubit>().checkout(userId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
