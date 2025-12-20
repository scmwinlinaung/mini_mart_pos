import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/logic/category/category_cubit.dart';
import '../../data/models/product.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_scaffold.dart';
import '../widgets/language_selector.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/pagination_controls.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryCubit(),
      child: const CategoryManagementView(),
    );
  }
}

class CategoryManagementView extends StatelessWidget {
  const CategoryManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      appBar: DesktopAppBar(
        title: AppStrings.categoryManagement,
        actions: const [
          LanguageSelector(),
        ],
      ),
      body: Row(
        children: [
          // Category Form
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
              child: const CategoryForm(),
            ),
          ),
          const SizedBox(width: 16),
          // Category List
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
              child: const CategoryList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryForm extends StatelessWidget {
  const CategoryForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.isEditing ? AppStrings.editCategory : AppStrings.addNewCategory,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (state.isEditing)
                  IconButton(
                    onPressed: () => context.read<CategoryCubit>().clearForm(),
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
                    // Category Name
                    TextFormField(
                      initialValue: state.name,
                      onChanged: (value) => context.read<CategoryCubit>().updateName(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.categoryName,
                        hintText: AppStrings.enterCategoryName,
                        border: const OutlineInputBorder(),
                        errorText: state.nameError,
                        prefixIcon: const Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      initialValue: state.description,
                      onChanged: (value) => context.read<CategoryCubit>().updateDescription(value),
                      decoration: InputDecoration(
                        labelText: AppStrings.description,
                        hintText: AppStrings.enterDescription,
                        border: const OutlineInputBorder(),
                        errorText: state.descriptionError,
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : () => context.read<CategoryCubit>().saveCategory(),
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
                              onPressed: () => context.read<CategoryCubit>().clearError(),
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
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.blue.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.categoryStatistics,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              if (state.isLoadingStatistics) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(AppStrings.totalCategories, state.totalCategories.toString()),
                          _buildStatRow(AppStrings.categoriesWithProducts, state.categoriesWithProducts.toString()),
                          _buildStatRow(AppStrings.totalProducts, state.totalProducts.toString()),
                          _buildStatRow(AppStrings.lowStockItems, state.totalLowStockItems.toString()),
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

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

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
                    AppStrings.categories,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  // Refresh Button
                  IconButton(
                    onPressed: () => context.read<CategoryCubit>().refreshData(),
                    icon: const Icon(Icons.refresh),
                    tooltip: AppStrings.refresh,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Field
              TextField(
                onChanged: (value) => context.read<CategoryCubit>().searchCategories(value),
                decoration: InputDecoration(
                  hintText: AppStrings.searchCategories,
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
        // Category Table
        Expanded(
          child: BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              if (state.isLoading && state.categories.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state.categories.isEmpty && state.searchTerm.isNotEmpty) {
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
                        AppStrings.noCategoriesFound,
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

              if (state.categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noCategoriesFound,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.addFirstCategory,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Page info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${((state.currentPage - 1) * state.itemsPerPage) + 1}-${(state.currentPage - 1) * state.itemsPerPage + state.categories.length} of ${state.totalItems}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 16,
                        columns: [
                          DataColumn(
                            label: Text(AppStrings.categoryName),
                          ),
                          DataColumn(
                            label: Text(AppStrings.description),
                          ),
                          DataColumn(
                            label: Text(AppStrings.products),
                          ),
                          DataColumn(
                            label: Text(AppStrings.stock),
                          ),
                          DataColumn(
                            label: Text(AppStrings.actions),
                          ),
                        ],
                        rows: state.categories.map((category) {
                          final statistics = state.categoryStatistics
                              .where((stat) => stat['categoryId'] == category.id)
                              .firstOrNull;

                          final productCount = statistics?['productCount'] as int? ?? 0;
                          final totalStock = statistics?['totalStock'] as int? ?? 0;
                          final lowStockCount = statistics?['lowStockCount'] as int? ?? 0;

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      size: 20,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    category.description ?? AppStrings.noDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: category.description != null
                                          ? null
                                          : Colors.grey.shade500,
                                      fontStyle: category.description != null
                                          ? null
                                          : FontStyle.italic,
                                    ),
                                  ),
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
                                  totalStock.toString(),
                                  style: TextStyle(
                                    color: totalStock > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                                    fontWeight: totalStock > 0 ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit Button
                                    IconButton(
                                      onPressed: () => context.read<CategoryCubit>().selectCategory(category),
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
                                          : () => _showDeleteConfirmation(context, category),
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
                    ),
                  ),
                  // Pagination Controls
                  PaginationControls<CategoryCubit, CategoryState>(
                    cubit: context.read<CategoryCubit>(),
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    onPageChanged: (page) => context.read<CategoryCubit>().goToPage(page),
                    itemsPerPage: state.itemsPerPage,
                    onItemsPerPageChanged: (itemsPerPage) => context.read<CategoryCubit>().changeItemsPerPage(itemsPerPage),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.deleteCategory),
          content: Text('${AppStrings.deleteCategoryConfirmation} "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<CategoryCubit>().deleteCategory(category.id);
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