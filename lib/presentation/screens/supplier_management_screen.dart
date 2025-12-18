import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/supplier/supplier_cubit.dart';
import '../../data/models/product.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/language_selector.dart';
import '../../core/constants/app_strings.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupplierCubit(),
      child: const SupplierManagementView(),
    );
  }
}

class SupplierManagementView extends StatelessWidget {
  const SupplierManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: AppStrings.supplierManagement,
        actions: const [
          LanguageSelector(),
        ],
      ),
      body: Row(
        children: [
          // Supplier Form
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const SupplierForm(),
            ),
          ),
          const SizedBox(width: 16),
          // Supplier List
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const SupplierList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierForm extends StatelessWidget {
  const SupplierForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.isEditing ? AppStrings.editSupplier : AppStrings.addNewSupplier,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (state.isEditing)
                  IconButton(
                    onPressed: () => context.read<SupplierCubit>().clearForm(),
                    icon: const Icon(Icons.close),
                    tooltip: AppStrings.cancel,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Name
                    TextFormField(
                      initialValue: state.companyName,
                      onChanged: (value) => context.read<SupplierCubit>().updateCompanyName(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.companyName,
                        hintText: AppStrings.enterCompanyName,
                        border: const OutlineInputBorder(),
                        errorText: state.companyNameError,
                        prefixIcon: const Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Name
                    TextFormField(
                      initialValue: state.contactName,
                      onChanged: (value) => context.read<SupplierCubit>().updateContactName(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.contactName,
                        hintText: AppStrings.enterContactName,
                        border: const OutlineInputBorder(),
                        errorText: state.contactNameError,
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      initialValue: state.phoneNumber,
                      onChanged: (value) => context.read<SupplierCubit>().updatePhoneNumber(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.phoneNumber,
                        hintText: AppStrings.enterPhoneNumber,
                        border: const OutlineInputBorder(),
                        errorText: state.phoneNumberError,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      initialValue: state.email,
                      onChanged: (value) => context.read<SupplierCubit>().updateEmail(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.email,
                        hintText: AppStrings.enterEmail,
                        border: const OutlineInputBorder(),
                        errorText: state.emailError,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      initialValue: state.address,
                      onChanged: (value) => context.read<SupplierCubit>().updateAddress(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.address,
                        hintText: AppStrings.enterAddress,
                        border: const OutlineInputBorder(),
                        errorText: state.addressError,
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : () => context.read<SupplierCubit>().saveSupplier(),
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(state.isEditing ? AppStrings.update : AppStrings.save),
                      ),
                    ),

                    // Error Message
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.read<SupplierCubit>().clearError(),
                              icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Statistics Summary
                Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2, color: Colors.orange.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.supplierStatistics,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              if (state.isLoadingStatistics) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(AppStrings.totalSuppliers, state.totalSuppliers.toString()),
                          _buildStatRow(AppStrings.suppliersWithProducts, state.suppliersWithProducts.toString()),
                          _buildStatRow(AppStrings.totalProducts, state.totalProducts.toString()),
                          _buildStatRow(AppStrings.lowStockItems, state.totalLowStockItems.toString()),
                          _buildStatRow(AppStrings.totalInventoryValue, '\$${state.totalInventoryValue.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class SupplierList extends StatelessWidget {
  const SupplierList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Search
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    AppStrings.suppliers,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  // Refresh Button
                  IconButton(
                    onPressed: () => context.read<SupplierCubit>().refreshData(),
                    icon: const Icon(Icons.refresh),
                    tooltip: AppStrings.refresh,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Field
              TextField(
                onChanged: (value) => context.read<SupplierCubit>().searchSuppliers(value),
                decoration: InputDecoration(
                  hintText: AppStrings.searchSuppliers,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // Supplier Table
        Expanded(
          child: BlocBuilder<SupplierCubit, SupplierState>(
            builder: (context, state) {
              if (state.isLoading && state.suppliers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state.filteredSuppliers.isEmpty && state.searchTerm.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noSuppliersFound,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppStrings.searchResultsFor} "${state.searchTerm}"',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state.filteredSuppliers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noSuppliersFound,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.addFirstSupplier,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 16,
                  columns: [
                    DataColumn(
                      label: Text(AppStrings.companyName),
                    ),
                    DataColumn(
                      label: Text(AppStrings.contactName),
                    ),
                    DataColumn(
                      label: Text(AppStrings.contactInfo),
                    ),
                    DataColumn(
                      label: Text(AppStrings.products),
                    ),
                    DataColumn(
                      label: Text(AppStrings.inventoryValue),
                    ),
                    DataColumn(
                      label: Text(AppStrings.actions),
                    ),
                  ],
                  rows: state.filteredSuppliers.map((supplier) {
                    final statistics = state.supplierStatistics
                        .where((stat) => stat['supplierId'] == supplier.id)
                        .firstOrNull;

                    final productCount = statistics?['productCount'] as int? ?? 0;
                    final totalValue = statistics?['totalValue'] as double? ?? 0.0;
                    final lowStockCount = statistics?['lowStockCount'] as int? ?? 0;

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 20,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(supplier.companyName),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            supplier.contactName ?? AppStrings.notProvided,
                            style: TextStyle(
                              color: supplier.contactName != null
                                  ? null
                                  : Colors.grey.shade500,
                              fontStyle: supplier.contactName != null
                                  ? null
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (supplier.email != null && supplier.email!.isNotEmpty)
                                Text(
                                  supplier.email!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (supplier.phoneNumber != null && supplier.phoneNumber!.isNotEmpty)
                                Text(
                                  supplier.phoneNumber!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (supplier.email == null && supplier.phoneNumber == null)
                                Text(
                                  AppStrings.notProvided,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Text(
                                productCount.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (lowStockCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '!',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '\$${totalValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: totalValue > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                              fontWeight: totalValue > 0 ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit Button
                              IconButton(
                                onPressed: () => context.read<SupplierCubit>().selectSupplier(supplier),
                                icon: const Icon(Icons.edit),
                                tooltip: AppStrings.edit,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              // Delete Button
                              IconButton(
                                onPressed: productCount > 0
                                    ? null
                                    : () => _showDeleteConfirmation(context, supplier),
                                icon: const Icon(Icons.delete),
                                tooltip: productCount > 0 ? AppStrings.cannotDelete : AppStrings.delete,
                                color: productCount > 0 ? Colors.grey.shade400 : Colors.red,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.deleteSupplier),
          content: Text('${AppStrings.deleteSupplierConfirmation} "${supplier.companyName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SupplierCubit>().deleteSupplier(supplier.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppStrings.delete),
            ),
          ],
        );
      },
    );
  }
}