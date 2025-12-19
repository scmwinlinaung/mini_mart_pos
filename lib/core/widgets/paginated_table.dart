import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../../presentation/widgets/language_selector.dart';

/// Column configuration for the paginated table
class TableColumnConfig<T> {
  final String headerKey;
  final String? headerText;
  final Widget Function(T item, int index) cellBuilder;
  final double? width;
  final FlexFit fit;
  final Alignment? alignment;
  final TextStyle? headerStyle;
  final TextStyle? cellStyle;

  // Responsive properties
  final double? minWidth;
  final double? maxWidth;
  final double? widthPercentage;
  final bool? isFixed;

  const TableColumnConfig({
    required this.headerKey,
    this.headerText,
    required this.cellBuilder,
    this.width,
    this.fit = FlexFit.tight,
    this.alignment,
    this.headerStyle,
    this.cellStyle,
    this.minWidth,
    this.maxWidth,
    this.widthPercentage,
    this.isFixed = false,
  });
}

/// Pagination configuration
class PaginationConfig {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;
  final Function(int)? onItemsPerPageChanged;
  final List<int> availableItemsPerPage;

  const PaginationConfig({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.availableItemsPerPage = const [10, 20, 50, 100],
  });
}

/// Action configuration for table rows
class ActionConfig<T> {
  final IconData icon;
  final String? tooltipKey;
  final String? tooltipText;
  final Function(T) onPressed;
  final Color? color;
  final bool enabled;

  const ActionConfig({
    required this.icon,
    this.tooltipKey,
    this.tooltipText,
    required this.onPressed,
    this.color,
    this.enabled = true,
  });
}

/// A reusable paginated table widget
class PaginatedTable<T> extends StatelessWidget {
  final List<T> data;
  final List<TableColumnConfig<T>> columns;
  final List<ActionConfig<T>>? actions;
  final PaginationConfig pagination;
  final String? emptyMessageKey;
  final String? emptyMessage;
  final Widget? emptyIcon;
  final bool showCheckbox;
  final List<T>? selectedItems;
  final Function(List<T>)? onSelectionChanged;
  final double rowHeight;
  final EdgeInsets rowPadding;
  final Color? headerColor;
  final Color? alternatingRowColor;
  final Function(T)? onRowTap;

  const PaginatedTable({
    Key? key,
    required this.data,
    required this.columns,
    this.actions,
    required this.pagination,
    this.emptyMessageKey,
    this.emptyMessage,
    this.emptyIcon,
    this.showCheckbox = false,
    this.selectedItems,
    this.onSelectionChanged,
    this.rowHeight = 56.0,
    this.rowPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.headerColor,
    this.alternatingRowColor,
    this.onRowTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Table Header
            _buildTableHeader(context, constraints.maxWidth),
            // Table Body
            Expanded(
              child: data.isEmpty
                  ? _buildEmptyState(context)
                  : _buildTableBody(context, constraints.maxWidth),
            ),
            // Pagination Controls
            _buildPaginationControls(context),
          ],
        );
      },
    );
  }

  Widget _buildTableHeader(BuildContext context, double tableWidth) {
    final availableWidth = _calculateAvailableWidth(tableWidth);
    final columnWidths = _calculateColumnWidths(availableWidth);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: headerColor ?? Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (showCheckbox) ...[
            Container(
              width: 40,
              padding: const EdgeInsets.only(left: 8),
              child: Checkbox(
                value: selectedItems?.length == data.length && data.isNotEmpty,
                onChanged: (value) {
                  if (value == true) {
                    onSelectionChanged?.call(List.from(data));
                  } else {
                    onSelectionChanged?.call([]);
                  }
                },
              ),
            ),
          ],
          ...columns.asMap().entries.map((entry) {
            final index = entry.key;
            final column = entry.value;
            final width = columnWidths[index];

            if (column.isFixed == true) {
              return Container(
                width: width,
                padding: rowPadding,
                alignment: column.alignment ?? Alignment.centerLeft,
                child: Text(
                  column.headerText ?? context.getString(column.headerKey),
                  style:
                      column.headerStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                ),
              );
            } else {
              return Expanded(
                flex: _getFlexFactor(column),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: column.minWidth ?? 60,
                    maxWidth: column.maxWidth ?? double.infinity,
                  ),
                  padding: rowPadding,
                  alignment: column.alignment ?? Alignment.centerLeft,
                  child: Text(
                    column.headerText ?? context.getString(column.headerKey),
                    style:
                        column.headerStyle ??
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                  ),
                ),
              );
            }
          }).toList(),
          if (actions != null && actions!.isNotEmpty)
            Container(
              width: actions!.length * 48.0,
              padding: const EdgeInsets.only(left: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                context.getString(AppStrings.actions),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableBody(BuildContext context, double tableWidth) {
    final availableWidth = _calculateAvailableWidth(tableWidth);
    final columnWidths = _calculateColumnWidths(availableWidth);

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isSelected = selectedItems?.contains(item) ?? false;
        final isAlternating = index % 2 == 1;

        return InkWell(
          onTap: onRowTap != null ? () => onRowTap!(item) : null,
          child: Container(
            height: rowHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : isAlternating
                  ? alternatingRowColor ?? Colors.grey[50]
                  : null,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                if (showCheckbox) ...[
                  Container(
                    width: 40,
                    padding: const EdgeInsets.only(left: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        final newSelection = List<T>.from(selectedItems ?? []);
                        if (value == true) {
                          newSelection.add(item);
                        } else {
                          newSelection.remove(item);
                        }
                        onSelectionChanged?.call(newSelection);
                      },
                    ),
                  ),
                ],
                ...columns.asMap().entries.map((entry) {
                  final column = entry.value;
                  final width = columnWidths[entry.key];

                  if (column.isFixed == true) {
                    return Container(
                      width: width,
                      padding: rowPadding,
                      alignment: column.alignment ?? Alignment.centerLeft,
                      child: column.cellBuilder(item, index),
                    );
                  } else {
                    return Expanded(
                      flex: _getFlexFactor(column),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: column.minWidth ?? 60,
                          maxWidth: column.maxWidth ?? double.infinity,
                        ),
                        padding: rowPadding,
                        alignment: column.alignment ?? Alignment.centerLeft,
                        child: column.cellBuilder(item, index),
                      ),
                    );
                  }
                }).toList(),
                if (actions != null && actions!.isNotEmpty)
                  Container(
                    width: actions!.length * 48.0,
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: actions!.map((action) {
                        return IconButton(
                          icon: Icon(action.icon),
                          onPressed: action.enabled
                              ? () => action.onPressed(item)
                              : null,
                          tooltip:
                              action.tooltipText ??
                              (action.tooltipKey != null
                                  ? context.getString(action.tooltipKey!)
                                  : null),
                          color: action.color,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          emptyIcon ??
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ??
                context.getString(emptyMessageKey ?? AppStrings.noDataFound),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    if (pagination.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info and items per page selector
          Row(
            children: [
              Text(
                'Showing ${((pagination.currentPage - 1) * pagination.itemsPerPage) + 1}-${(pagination.currentPage - 1) * pagination.itemsPerPage + data.length} of ${pagination.totalItems}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              if (pagination.onItemsPerPageChanged != null) ...[
                Text(
                  'Items per page: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                DropdownButton<int>(
                  value: pagination.itemsPerPage,
                  onChanged: (value) {
                    if (value != null) {
                      pagination.onItemsPerPageChanged!(value);
                    }
                  },
                  items: pagination.availableItemsPerPage.map((count) {
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text(count.toString()),
                    );
                  }).toList(),
                  underline: Container(),
                  isDense: true,
                ),
              ],
            ],
          ),

          // Page navigation
          Row(
            children: [
              IconButton(
                onPressed: pagination.currentPage > 1
                    ? () => pagination.onPageChanged(pagination.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Text(
                '${pagination.currentPage} / ${pagination.totalPages}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              IconButton(
                onPressed: pagination.currentPage < pagination.totalPages
                    ? () => pagination.onPageChanged(pagination.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getFlexFactor(TableColumnConfig<T> column) {
    if (column.width != null) return 0;

    // Default flex factors based on fit type
    switch (column.fit) {
      case FlexFit.tight:
        return 1;
      case FlexFit.loose:
        return 0;
    }
  }

  double _calculateAvailableWidth(double tableWidth) {
    double occupiedWidth = 0;

    // Checkbox width
    if (showCheckbox) {
      occupiedWidth += 40;
    }

    // Actions width
    if (actions != null && actions!.isNotEmpty) {
      occupiedWidth += actions!.length * 48.0;
    }

    // Fixed width columns
    for (final column in columns) {
      if (column.isFixed == true && column.width != null) {
        occupiedWidth += column.width!;
      }
    }

    return tableWidth - occupiedWidth;
  }

  List<double> _calculateColumnWidths(double availableWidth) {
    final widths = <double>[];
    var remainingWidth = availableWidth;
    var flexibleColumns = <TableColumnConfig<T>>[];
    var fixedTotalWidth = 0.0;

    // Separate fixed and flexible columns
    for (final column in columns) {
      if (column.isFixed == true) {
        if (column.width != null) {
          widths.add(column.width!);
          fixedTotalWidth += column.width!;
        } else if (column.widthPercentage != null) {
          final width = availableWidth * (column.widthPercentage! / 100);
          widths.add(width);
          fixedTotalWidth += width;
        } else {
          widths.add(0);
          flexibleColumns.add(column);
        }
      } else {
        widths.add(0);
        flexibleColumns.add(column);
      }
    }

    // Distribute remaining width among flexible columns
    if (flexibleColumns.isNotEmpty) {
      final flexPerColumn =
          (remainingWidth - fixedTotalWidth) / flexibleColumns.length;

      for (var i = 0; i < columns.length; i++) {
        if (widths[i] == 0) {
          final column = columns[i];
          final minWidth = column.minWidth ?? 60;
          final maxWidth = column.maxWidth ?? double.infinity;
          var calculatedWidth = flexPerColumn;

          // Apply min/max constraints
          calculatedWidth = calculatedWidth.clamp(minWidth, maxWidth);
          widths[i] = calculatedWidth;
        }
      }
    }

    return widths;
  }
}

/// A DataTable version of PaginatedTable for those who prefer the DataTable widget
class PaginatedDataTable<T> extends StatelessWidget {
  final List<T> data;
  final List<TableColumnConfig<T>> columns;
  final List<ActionConfig<T>>? actions;
  final PaginationConfig pagination;
  final String? emptyMessageKey;
  final String? emptyMessage;
  final Widget? emptyIcon;

  const PaginatedDataTable({
    Key? key,
    required this.data,
    required this.columns,
    this.actions,
    required this.pagination,
    this.emptyMessageKey,
    this.emptyMessage,
    this.emptyIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: [
                ...columns.map((column) {
                  return DataColumn(
                    label: Text(
                      column.headerText ?? context.getString(column.headerKey),
                      style:
                          column.headerStyle ??
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                if (actions != null && actions!.isNotEmpty)
                  DataColumn(
                    label: Text(
                      context.getString(AppStrings.actions),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              rows: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return DataRow(
                  cells: [
                    ...columns.map((column) {
                      return DataCell(column.cellBuilder(item, index));
                    }).toList(),
                    if (actions != null && actions!.isNotEmpty)
                      DataCell(
                        Row(
                          children: actions!.map((action) {
                            return IconButton(
                              icon: Icon(action.icon),
                              onPressed: action.enabled
                                  ? () => action.onPressed(item)
                                  : null,
                              tooltip:
                                  action.tooltipText ??
                                  (action.tooltipKey != null
                                      ? context.getString(action.tooltipKey!)
                                      : null),
                              color: action.color,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (pagination.totalPages > 1) _buildPaginationControls(context),
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info and items per page selector
          Row(
            children: [
              Text(
                'Showing ${((pagination.currentPage - 1) * pagination.itemsPerPage) + 1}-${(pagination.currentPage - 1) * pagination.itemsPerPage + data.length} of ${pagination.totalItems}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              if (pagination.onItemsPerPageChanged != null) ...[
                Text(
                  'Items per page: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                DropdownButton<int>(
                  value: pagination.itemsPerPage,
                  onChanged: (value) {
                    if (value != null) {
                      pagination.onItemsPerPageChanged!(value);
                    }
                  },
                  items: pagination.availableItemsPerPage.map((count) {
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text(count.toString()),
                    );
                  }).toList(),
                  underline: Container(),
                  isDense: true,
                ),
              ],
            ],
          ),

          // Page navigation
          Row(
            children: [
              IconButton(
                onPressed: pagination.currentPage > 1
                    ? () => pagination.onPageChanged(pagination.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Text(
                '${pagination.currentPage} / ${pagination.totalPages}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              IconButton(
                onPressed: pagination.currentPage < pagination.totalPages
                    ? () => pagination.onPageChanged(pagination.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
