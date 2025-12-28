import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/purchases.dart';
import '../../data/logic/purchase/purchase_cubit.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/add_purchase_dialog.dart';

class PurchaseManagementScreen extends StatefulWidget {
  const PurchaseManagementScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseManagementScreen> createState() =>
      _PurchaseManagementScreenState();
}

class _PurchaseManagementScreenState extends State<PurchaseManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late PurchaseCubit _purchaseCubit;

  @override
  void initState() {
    super.initState();
    _purchaseCubit = context.read<PurchaseCubit>();
    _searchController.addListener(_onSearchChanged);
    _purchaseCubit.loadPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _purchaseCubit.searchPurchases(_searchController.text);
  }

  void _showPurchaseDetails(PurchaseWithItems purchase) {
    showDialog(
      context: context,
      builder: (context) => _buildPurchaseDetailsDialog(purchase),
    );
  }

  void _showAddPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseDialog(),
    ).then((result) {
      if (result != null) {
        _purchaseCubit.addPurchase(result['purchaseData'], result['itemsData']);
      }
    });
  }

  void _markAsReceived(int purchaseId) {
    _purchaseCubit.updatePurchaseStatus(purchaseId, PurchaseStatus.received);
    Navigator.of(context).pop();
  }

  void _deletePurchase(int purchaseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase'),
        content: const Text(
          'Are you sure you want to delete this purchase? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _purchaseCubit.deletePurchase(purchaseId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _purchaseCubit,
      child: DesktopScaffold(
        appBar: const DesktopAppBar(
          showBackButton: true,
          title: 'Purchase Management',
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Purchases',
                        hintText: 'Search by supplier or invoice number...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<PurchaseCubit, PurchaseState>(
                      builder: (context, state) {
                        PurchaseStatus? statusFilter = state is PurchaseLoaded
                            ? state.statusFilter
                            : null;
                        return DropdownButtonFormField<PurchaseStatus?>(
                          value: statusFilter,
                          decoration: InputDecoration(
                            labelText: 'Filter by Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Status'),
                            ),
                            ...PurchaseStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.displayName),
                              );
                            }).toList(),
                          ],
                          onChanged: (status) {
                            context.read<PurchaseCubit>().filterPurchases(
                              status,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddPurchaseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('New Purchase'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<PurchaseCubit, PurchaseState>(
                  builder: (context, state) {
                    if (state is PurchaseLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is PurchaseError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading purchases',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.read<PurchaseCubit>().loadPurchases(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is! PurchaseLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredPurchases = state.filteredPurchases;
                    final totalAmount = filteredPurchases.fold<double>(
                      0,
                      (sum, purchase) => sum + purchase.purchase.totalAmount,
                    );
                    final pendingCount = filteredPurchases
                        .where(
                          (p) => p.purchase.status == PurchaseStatus.pending,
                        )
                        .length;
                    final receivedCount = filteredPurchases
                        .where(
                          (p) => p.purchase.status == PurchaseStatus.received,
                        )
                        .length;

                    return Column(
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Purchases',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '\$$totalAmount',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      pendingCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Received',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      receivedCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Purchase Table
                        Expanded(
                          child: filteredPurchases.isEmpty
                              ? _buildEmptyState(state.purchases.isEmpty)
                              : _buildPurchaseTable(filteredPurchases),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasPurchases) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasPurchases ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasPurchases ? 'No purchases found' : 'No purchases yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPurchases
                ? 'Try adjusting your search terms or filters'
                : 'Add your first purchase to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (!hasPurchases) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPurchaseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add First Purchase'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseTable(List<PurchaseWithItems> filteredPurchases) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Purchase ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Supplier',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Invoice #',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...filteredPurchases.asMap().entries.map((entry) {
              final index = entry.key;
              final purchaseWithItems = entry.value;
              final purchase = purchaseWithItems.purchase;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '#${purchase.purchaseId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            purchase.supplierDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (purchaseWithItems.items.any(
                            (item) => item.isExpiringSoon || item.isExpired,
                          ))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    purchaseWithItems.items.any(
                                      (item) => item.isExpired,
                                    )
                                    ? Colors.red[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                purchaseWithItems.items.any(
                                      (item) => item.isExpired,
                                    )
                                    ? 'Has Expired Items'
                                    : 'Items Expiring Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      purchaseWithItems.items.any(
                                        (item) => item.isExpired,
                                      )
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        purchase.invoiceDisplay,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            purchase.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          purchase.status.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(purchase.status),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        purchase.formattedTotalAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                _showPurchaseDetails(purchaseWithItems),
                            icon: const Icon(Icons.visibility, size: 20),
                            tooltip: 'View Details',
                            color: Colors.blue,
                          ),
                          if (purchase.status == PurchaseStatus.pending) ...[
                            IconButton(
                              onPressed: () =>
                                  _deletePurchase(purchase.purchaseId),
                              icon: const Icon(Icons.delete, size: 20),
                              tooltip: 'Delete Purchase',
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseDetailsDialog(PurchaseWithItems purchaseWithItems) {
    final purchase = purchaseWithItems.purchase;
    final items = purchaseWithItems.items;

    return Dialog(
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  Icon(Icons.receipt_long, color: Colors.indigo[700]),
                  const SizedBox(width: 12),
                  Text(
                    'Purchase Details',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Purchase ID',
                          '#${purchase.purchaseId}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Status',
                          purchase.status.displayName,
                          color: _getStatusColor(purchase.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Supplier',
                          purchase.supplierDisplay,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Invoice #',
                          purchase.invoiceDisplay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Purchase Date',
                          '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Total Amount',
                          purchase.formattedTotalAmount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Purchase Items',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
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
                                flex: 1,
                                child: Text(
                                  'Product',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Barcode',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Quantity',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Unit Price',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items
                            .map(
                              (item) => Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        item.productName ?? 'Unknown',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(item.barcode ?? '—'),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(item.quantity.toString()),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(item.formattedBuyPrice),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(item.formattedTotal),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                  if (items.any(
                    (item) => item.isExpiringSoon || item.isExpired,
                  )) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: items.any((item) => item.isExpired)
                            ? Colors.red[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                items.any((item) => item.isExpired)
                                    ? Icons.warning
                                    : Icons.info,
                                color: items.any((item) => item.isExpired)
                                    ? Colors.red
                                    : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                items.any((item) => item.isExpired)
                                    ? 'Expired Items'
                                    : 'Items Expiring Soon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: items.any((item) => item.isExpired)
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          ...items
                              .where(
                                (item) => item.isExpiringSoon || item.isExpired,
                              )
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${item.productName} - ${item.expiryDisplay}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: items.any((item) => item.isExpired)
                                          ? Colors.red[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      if (purchase.status == PurchaseStatus.pending)
                        ElevatedButton(
                          onPressed: () => _markAsReceived(purchase.purchaseId),
                          child: const Text('Mark as Received'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return Colors.orange;
      case PurchaseStatus.received:
        return Colors.green;
      case PurchaseStatus.cancelled:
        return Colors.red;
    }
  }
}
