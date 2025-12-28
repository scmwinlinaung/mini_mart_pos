import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mini_mart_pos/core/widgets/paginated_table.dart';
import 'package:mini_mart_pos/data/logic/sales/sales_cubit.dart';
import 'package:mini_mart_pos/data/models/sales.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import 'sale_detail_screen.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesCubit()..loadSales(),
      child: const SalesHistoryView(),
    );
  }
}

class SalesHistoryView extends StatefulWidget {
  const SalesHistoryView({Key? key}) : super(key: key);

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  final TextEditingController _invoiceController = TextEditingController();
  final Debouncer _debouncer = Debouncer(const Duration(milliseconds: 500));

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: 'Sales History',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: _buildSalesList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Date range filter
          ElevatedButton.icon(
            icon: const Icon(Icons.date_range, size: 20),
            label: const Text('Date Range'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => _selectDateRange(context),
          ),
          const SizedBox(width: 16),
          // Clear filters button
          BlocBuilder<SalesCubit, SalesState>(
            buildWhen: (previous, current) =>
                previous.startDate != current.startDate ||
                previous.endDate != current.endDate ||
                previous.paymentMethodFilter != current.paymentMethodFilter,
            builder: (context, state) {
              final hasFilters = state.startDate != null ||
                  state.endDate != null ||
                  state.paymentMethodFilter != null;

              if (!hasFilters) return const SizedBox.shrink();

              return OutlinedButton.icon(
                icon: const Icon(Icons.clear, size: 20),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  context.read<SalesCubit>().clearFilters();
                  _invoiceController.clear();
                },
              );
            },
          ),
          const SizedBox(width: 24),
          // Invoice search
          Expanded(
            child: TextField(
              controller: _invoiceController,
              decoration: InputDecoration(
                hintText: 'Search by Invoice No...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _debouncer.run(() {
                  context.read<SalesCubit>().searchByInvoiceNo(value);
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // Payment method filter
          BlocBuilder<SalesCubit, SalesState>(
            buildWhen: (previous, current) =>
                previous.paymentMethodFilter != current.paymentMethodFilter,
            builder: (context, state) {
              return DropdownButton<String>(
                value: state.paymentMethodFilter,
                hint: const Text('Payment Method'),
                items: const [
                  DropdownMenuItem(
                    value: 'CASH',
                    child: Row(
                      children: [
                        Icon(Icons.money, size: 18),
                        SizedBox(width: 8),
                        Text('Cash'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'CARD',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, size: 18),
                        SizedBox(width: 8),
                        Text('Card'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  context.read<SalesCubit>().filterByPaymentMethod(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList(BuildContext context) {
    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, state) {
        if (state.isLoading && state.sales.isEmpty) {
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
                  'Error loading sales',
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
                    context.read<SalesCubit>().loadSales();
                  },
                ),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: PaginatedTable<Sale>(
            data: state.sales,
            columns: [
              TableColumnConfig<Sale>(
                headerKey: 'Invoice',
                headerText: 'Invoice',
                cellBuilder: (sale, index) => Text(
                  sale.invoiceNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                width: 120,
                isFixed: true,
              ),
              TableColumnConfig<Sale>(
                headerKey: 'Date',
                headerText: 'Date',
                cellBuilder: (sale, index) => Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(sale.createdAt),
                  style: const TextStyle(fontSize: 13),
                ),
                width: 160,
                isFixed: true,
              ),
              TableColumnConfig<Sale>(
                headerKey: 'Cashier',
                headerText: 'Cashier',
                cellBuilder: (sale, index) => Text(
                  sale.userName ?? 'Unknown',
                  style: const TextStyle(fontSize: 13),
                ),
                width: 120,
                isFixed: true,
              ),
              TableColumnConfig<Sale>(
                headerKey: 'Payment',
                headerText: 'Payment',
                cellBuilder: (sale, index) => _buildPaymentChip(sale),
                width: 100,
                isFixed: true,
              ),
              TableColumnConfig<Sale>(
                headerKey: 'Status',
                headerText: 'Status',
                cellBuilder: (sale, index) => _buildStatusChip(sale),
                width: 100,
                isFixed: true,
              ),
              TableColumnConfig<Sale>(
                headerKey: 'Total',
                headerText: 'Total',
                cellBuilder: (sale, index) => Text(
                  sale.formattedGrandTotal,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                width: 120,
                isFixed: true,
                alignment: Alignment.centerRight,
              ),
            ],
            actions: [
              ActionConfig<Sale>(
                icon: Icons.visibility,
                tooltipText: 'View Details',
                color: Colors.blue,
                onPressed: (sale) => _showSaleDetails(context, sale.invoiceNo),
              ),
            ],
            pagination: PaginationConfig(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              totalItems: state.totalItems,
              itemsPerPage: state.itemsPerPage,
              onPageChanged: (page) {
                context.read<SalesCubit>().goToPage(page);
              },
              onItemsPerPageChanged: (size) {
                context.read<SalesCubit>().changeItemsPerPage(size);
              },
              availableItemsPerPage: const [10, 20, 50, 100],
            ),
            emptyMessage: 'No sales found',
            emptyIcon: const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            onRowTap: (sale) => _showSaleDetails(context, sale.invoiceNo),
          ),
        );
      },
    );
  }

  Widget _buildPaymentChip(Sale sale) {
    final isCash = sale.paymentMethod == 'CASH';
    return Chip(
      label: Text(
        sale.paymentMethod ?? 'N/A',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: isCash ? Colors.green[100] : Colors.blue[100],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip(Sale sale) {
    final isPaid = sale.paymentStatus == 'PAID';
    return Chip(
      label: Text(
        sale.paymentStatus ?? 'UNKNOWN',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isPaid ? Colors.green[50] : Colors.orange[50],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: context.read<SalesCubit>().state.startDate != null &&
              context.read<SalesCubit>().state.endDate != null
          ? DateTimeRange(
              start: context.read<SalesCubit>().state.startDate!,
              end: context.read<SalesCubit>().state.endDate!,
            )
          : null,
    );

    if (picked != null) {
      if (!context.mounted) return;
      context.read<SalesCubit>().filterByDateRange(
            picked.start,
            picked.end,
          );
    }
  }

  void _showSaleDetails(BuildContext context, String invoiceNo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaleDetailScreen(invoiceNo: invoiceNo),
      ),
    );
  }
}

// Debouncer utility for search
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer(this.delay);

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}