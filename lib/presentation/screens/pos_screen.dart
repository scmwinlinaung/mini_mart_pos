import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/data/logic/cart/cart_cubit.dart';
import 'package:mini_mart_pos/data/logic/scanner/scanner_cubit.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _scanCtrl = TextEditingController();
  final FocusNode _scanFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Keep focus on scan input
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scanFocus.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("POS Terminal")),
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
                  ),
                );
              } else if (state.status == CartStatus.failure) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Error"),
                    content: Text(state.errorMessage ?? ""),
                  ),
                );
              }
            },
          ),
        ],
        child: Row(
          children: [
            // LEFT: Cart Items
            Expanded(flex: 2, child: _buildCartList()),

            // RIGHT: Controls
            Expanded(flex: 1, child: _buildControls(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const Center(child: Text("Cart is Empty"));
        }
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return ListTile(
              title: Text(item.product.name),
              subtitle: Text(item.product.barcode),
              trailing: Text(
                "${item.quantity} x \$${item.product.priceDouble.toStringAsFixed(2)} = \$${(item.total / 100).toStringAsFixed(2)}",
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Scanner Input
          TextField(
            controller: _scanCtrl,
            focusNode: _scanFocus,
            decoration: const InputDecoration(
              labelText: "Scan Barcode",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code_scanner),
            ),
            onSubmitted: (val) {
              context.read<ScannerCubit>().scanBarcode(val);
            },
            autofocus: true,
          ),

          const Spacer(),

          // Totals Display
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              return Column(
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${(state.grandTotal / 100).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Checkout Button
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
                          : const Icon(Icons.payment),
                      label: const Text("PAY CASH"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      onPressed:
                          state.status == CartStatus.processing ||
                              state.items.isEmpty
                          ? null
                          : () => context.read<CartCubit>().checkout(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
