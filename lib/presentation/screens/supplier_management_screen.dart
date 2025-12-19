import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/supplier/supplier_cubit.dart';
import '../../data/models/product.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/language_selector.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/paginated_table.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
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
        title: context.getString(AppStrings.supplierManagement),
        actions: const [LanguageSelector()],
      ),
      body: Row(
        children: [
          // Supplier Form (Left Side)
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: BlocBuilder<SupplierCubit, SupplierState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.getString(
                                state.isEditing
                                    ? AppStrings.editSupplier
                                    : AppStrings.addNewSupplier,
                              ),
                              style: context.getTextStyle(
                                Theme.of(context).textTheme.headlineSmall!,
                              ),
                            ),
                            if (state.isEditing)
                              IconButton(
                                onPressed: () =>
                                    context.read<SupplierCubit>().clearForm(),
                                icon: const Icon(Icons.close),
                                tooltip: context.getString(AppStrings.cancel),
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
                                  onChanged: (value) => context
                                      .read<SupplierCubit>()
                                      .updateCompanyName(value),
                                  decoration: InputDecoration(
                                    labelText: context.getString(
                                      AppStrings.companyName,
                                    ),
                                    hintText: context.getString(
                                      AppStrings.enterCompanyName,
                                    ),
                                    border: const OutlineInputBorder(),
                                    errorText: state.companyNameError,
                                    prefixIcon: const Icon(Icons.business),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Contact Name
                                TextFormField(
                                  initialValue: state.contactName,
                                  onChanged: (value) => context
                                      .read<SupplierCubit>()
                                      .updateContactName(value),
                                  decoration: InputDecoration(
                                    labelText: context.getString(
                                      AppStrings.contactName,
                                    ),
                                    hintText: context.getString(
                                      AppStrings.enterContactName,
                                    ),
                                    border: const OutlineInputBorder(),
                                    errorText: state.contactNameError,
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Phone Number
                                TextFormField(
                                  initialValue: state.phoneNumber,
                                  onChanged: (value) => context
                                      .read<SupplierCubit>()
                                      .updatePhoneNumber(value),
                                  decoration: InputDecoration(
                                    labelText: context.getString(
                                      AppStrings.phoneNumber,
                                    ),
                                    hintText: context.getString(
                                      AppStrings.enterPhoneNumber,
                                    ),
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
                                  onChanged: (value) => context
                                      .read<SupplierCubit>()
                                      .updateEmail(value),
                                  decoration: InputDecoration(
                                    labelText: context.getString(
                                      AppStrings.email,
                                    ),
                                    hintText: context.getString(
                                      AppStrings.enterEmail,
                                    ),
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
                                  onChanged: (value) => context
                                      .read<SupplierCubit>()
                                      .updateAddress(value),
                                  decoration: InputDecoration(
                                    labelText: context.getString(
                                      AppStrings.address,
                                    ),
                                    hintText: context.getString(
                                      AppStrings.enterAddress,
                                    ),
                                    border: const OutlineInputBorder(),
                                    errorText: state.addressError,
                                    prefixIcon: const Icon(Icons.location_on),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),

                                // Save Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: state.isLoading
                                        ? null
                                        : () => _saveSupplier(context),
                                    child: state.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            context.getString(AppStrings.save),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Supplier List (Right Side)
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              child: BlocBuilder<SupplierCubit, SupplierState>(
                builder: (context, state) {
                  if (state.isLoading && state.filteredSuppliers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null && state.filteredSuppliers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.getString(AppStrings.error),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<SupplierCubit>().loadSuppliers(),
                            child: Text(context.getString(AppStrings.retry)),
                          ),
                        ],
                      ),
                    );
                  }

                  return PaginatedTable<Supplier>(
                    data: state.filteredSuppliers,
                    pagination: PaginationConfig(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      totalItems: state.totalSuppliersCount,
                      itemsPerPage: state.pageSize,
                      onPageChanged: (page) =>
                          context.read<SupplierCubit>().goToPage(page),
                      onItemsPerPageChanged: (pageSize) => context
                          .read<SupplierCubit>()
                          .changePageSize(pageSize),
                    ),
                    columns: [
                      TableColumnConfig(
                        headerKey: AppStrings.companyName,
                        cellBuilder: (supplier, index) => Row(
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
                        width: 200,
                        minWidth: 200,
                        maxWidth: 230,
                      ),
                      TableColumnConfig(
                        headerKey: AppStrings.contactName,
                        cellBuilder: (supplier, index) => Text(
                          supplier.contactName ??
                              context.getString(AppStrings.notProvided),
                          style: TextStyle(
                            color: supplier.contactName != null
                                ? null
                                : Colors.grey.shade500,
                            fontStyle: supplier.contactName != null
                                ? null
                                : FontStyle.italic,
                          ),
                        ),
                        minWidth: 100,
                        width: 100,
                        maxWidth: 140,
                      ),
                      TableColumnConfig(
                        headerKey: AppStrings.contactInfo,
                        cellBuilder: (supplier, index) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (supplier.email != null &&
                                supplier.email!.isNotEmpty)
                              Text(
                                supplier.email!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            if (supplier.phoneNumber != null &&
                                supplier.phoneNumber!.isNotEmpty)
                              Text(
                                supplier.phoneNumber!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            if (supplier.email == null &&
                                supplier.phoneNumber == null)
                              Text(
                                context.getString(AppStrings.notProvided),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        width: 100,
                        minWidth: 100,
                        maxWidth: 140,
                      ),
                      TableColumnConfig(
                        headerKey: AppStrings.products,
                        cellBuilder: (supplier, index) {
                          final statistics = state.supplierStatistics
                              .where(
                                (stat) => stat['supplierId'] == supplier.id,
                              )
                              .firstOrNull;
                          final productCount =
                              statistics?['productCount'] as int? ?? 0;
                          final lowStockCount =
                              statistics?['lowStockCount'] as int? ?? 0;

                          return Row(
                            children: [
                              Text(
                                productCount.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (lowStockCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
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
                          );
                        },
                        minWidth: 20,
                      ),
                      TableColumnConfig(
                        headerKey: AppStrings.inventoryValue,
                        cellBuilder: (supplier, index) {
                          final statistics = state.supplierStatistics
                              .where(
                                (stat) => stat['supplierId'] == supplier.id,
                              )
                              .firstOrNull;
                          final totalValue =
                              statistics?['totalValue'] as double? ?? 0.0;

                          return Text(
                            '\$${totalValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: totalValue > 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: totalValue > 0
                                  ? FontWeight.bold
                                  : null,
                            ),
                          );
                        },
                        minWidth: 30,
                      ),
                    ],
                    actions: [
                      ActionConfig(
                        icon: Icons.edit,
                        tooltipKey: AppStrings.edit,
                        onPressed: (supplier) {
                          context.read<SupplierCubit>().selectSupplier(
                            supplier,
                          );
                        },
                      ),
                      ActionConfig(
                        icon: Icons.delete,
                        tooltipKey: AppStrings.delete,
                        onPressed: (supplier) {
                          final statistics = state.supplierStatistics
                              .where(
                                (stat) => stat['supplierId'] == supplier.id,
                              )
                              .firstOrNull;
                          final productCount =
                              statistics?['productCount'] as int? ?? 0;

                          if (productCount > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.getString(AppStrings.cannotDelete),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            _showDeleteConfirmation(context, supplier);
                          }
                        },
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

  void _saveSupplier(BuildContext context) {
    context.read<SupplierCubit>().saveSupplier();
  }

  void _showDeleteConfirmation(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.getString(AppStrings.deleteSupplier)),
          content: Text(
            '${context.getString(AppStrings.deleteSupplierConfirmation)} "${supplier.companyName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.getString(AppStrings.cancel)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<SupplierCubit>().deleteSupplier(supplier.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(context.getString(AppStrings.delete)),
            ),
          ],
        );
      },
    );
  }
}
