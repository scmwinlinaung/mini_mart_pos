import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mini_mart_pos/core/widgets/paginated_table.dart';
import 'package:mini_mart_pos/data/logic/sales/sales_cubit.dart';
import 'package:mini_mart_pos/data/models/sales.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';

class SaleDetailScreen extends StatelessWidget {
  final String invoiceNo;

  const SaleDetailScreen({
    Key? key,
    required this.invoiceNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesCubit()..loadSaleDetails(invoiceNo),
      child: SaleDetailView(invoiceNo: invoiceNo),
    );
  }
}

class SaleDetailView extends StatelessWidget {
  final String invoiceNo;

  const SaleDetailView({
    Key? key,
    required this.invoiceNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: 'Sale Details - $invoiceNo',
        showBackButton: true,
      ),
      body: BlocBuilder<SalesCubit, SalesState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading sale details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      context.read<SalesCubit>().loadSaleDetails(invoiceNo);
                    },
                  ),
                ],
              ),
            );
          }

          final saleWithItems = state.selectedSaleWithItems;
          if (saleWithItems == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sale not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSaleSummary(context, saleWithItems),
                const SizedBox(height: 24),
                _buildSaleItemsTable(context, saleWithItems),
                const SizedBox(height: 24),
                _buildSaleTotals(context, saleWithItems),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaleSummary(BuildContext context, SaleWithItems saleWithItems) {
    final sale = saleWithItems.sale;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sale Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Invoice No',
                    sale.invoiceNo,
                    Icons.receipt,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Date & Time',
                    DateFormat('MMM dd, yyyy - HH:mm:ss').format(sale.createdAt),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Cashier',
                    sale.userName ?? 'Unknown',
                    Icons.person,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Payment Method',
                    sale.paymentMethod ?? 'N/A',
                    Icons.payment,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Payment Status',
                    sale.paymentStatus ?? 'UNKNOWN',
                    Icons.check_circle,
                    statusColor: sale.paymentStatus == 'PAID'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Items',
                    '${saleWithItems.items.length} items',
                    Icons.shopping_cart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: statusColor ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleItemsTable(BuildContext context, SaleWithItems saleWithItems) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sale Items (${saleWithItems.items.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            height: 300,
            child: PaginatedTable<SaleItem>(
              data: saleWithItems.items,
              columns: [
                TableColumnConfig<SaleItem>(
                  headerKey: '#',
                  headerText: '#',
                  cellBuilder: (item, index) => Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  width: 60,
                  isFixed: true,
                ),
                TableColumnConfig<SaleItem>(
                  headerKey: 'Barcode',
                  headerText: 'Barcode',
                  cellBuilder: (item, index) => Text(
                    item.barcode ?? 'N/A',
                    style: const TextStyle(fontSize: 13),
                  ),
                  width: 120,
                  isFixed: true,
                ),
                TableColumnConfig<SaleItem>(
                  headerKey: 'Product',
                  headerText: 'Product Name',
                  cellBuilder: (item, index) => Text(
                    item.productName ?? 'Unknown',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TableColumnConfig<SaleItem>(
                  headerKey: 'Qty',
                  headerText: 'Qty',
                  cellBuilder: (item, index) => Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  width: 80,
                  isFixed: true,
                  alignment: Alignment.center,
                ),
                TableColumnConfig<SaleItem>(
                  headerKey: 'UnitPrice',
                  headerText: 'Unit Price',
                  cellBuilder: (item, index) => Text(
                    item.formattedUnitPrice,
                    style: const TextStyle(fontSize: 13),
                  ),
                  width: 100,
                  isFixed: true,
                  alignment: Alignment.centerRight,
                ),
                TableColumnConfig<SaleItem>(
                  headerKey: 'Total',
                  headerText: 'Total',
                  cellBuilder: (item, index) => Text(
                    item.formattedTotalPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  width: 100,
                  isFixed: true,
                  alignment: Alignment.centerRight,
                ),
              ],
              pagination: PaginationConfig(
                currentPage: 1,
                totalPages: 1,
                totalItems: 0,
                itemsPerPage: 1000,
                onPageChanged: (_) {},
              ),
              emptyMessage: 'No items found',
              emptyIcon: const Icon(
                Icons.shopping_basket,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleTotals(BuildContext context, SaleWithItems saleWithItems) {
    final sale = saleWithItems.sale;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTotalRow(context, 'Sub Total', sale.formattedSubTotal),
            _buildTotalRow(context, 'Tax Amount', sale.formattedTaxAmount),
            if (sale.discountAmount > 0)
              _buildTotalRow(
                context,
                'Discount',
                sale.formattedDiscountAmount,
                color: Colors.green,
              ),
            const Divider(height: 24, thickness: 2),
            _buildTotalRow(
              context,
              'Grand Total',
              sale.formattedGrandTotal,
              isGrandTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isGrandTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label + ':',
              style: TextStyle(
                fontSize: isGrandTotal ? 16 : 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrandTotal ? 20 : 15,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
