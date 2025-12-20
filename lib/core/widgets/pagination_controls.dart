import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A reusable pagination controls widget that can be used with any Cubit/BLoC
/// that implements the standard pagination interface
class PaginationControls<T extends Cubit<S>, S> extends StatelessWidget {
  final T cubit;
  final int currentPage;
  final int totalPages;
  final void Function(int) onPageChanged;
  final List<int> availableItemsPerPage;
  final int? itemsPerPage;
  final void Function(int)? onItemsPerPageChanged;
  final bool showItemsPerPageSelector;
  final bool showPageInfo;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const PaginationControls({
    Key? key,
    required this.cubit,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.availableItemsPerPage = const [10, 20, 50, 100],
    this.itemsPerPage,
    this.onItemsPerPageChanged,
    this.showItemsPerPageSelector = true,
    this.showPageInfo = true,
    this.padding,
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: borderColor ?? Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Items per page selector
          if (showItemsPerPageSelector && onItemsPerPageChanged != null) ...[
            Row(
              children: [
                Text(
                  'Items per page:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: itemsPerPage,
                      onChanged: (value) {
                        if (value != null) {
                          onItemsPerPageChanged!(value);
                        }
                      },
                      items: availableItemsPerPage.map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text(
                            count.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      isDense: true,
                      iconSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ] else const Spacer(),

          // Center - Page numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageNumbers(context),
              ),
            ),
          ),

          // Right side - Page info
          if (showPageInfo) ...[
            Text(
              '${currentPage}/${totalPages}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else const Spacer(),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    final List<Widget> pageNumbers = [];
    final maxVisiblePages = 5;

    // Always show first page
    if (currentPage > 3) {
      pageNumbers.add(_buildPageButton(context, 1));
      if (currentPage > 4) {
        pageNumbers.add(_buildEllipsis());
      }
    }

    // Calculate range of pages to show
    int startPage = (currentPage - 2).clamp(1, totalPages);
    int endPage = (currentPage + 2).clamp(startPage, totalPages);

    // Adjust to always show maxVisiblePages pages
    if (endPage - startPage + 1 < maxVisiblePages) {
      if (startPage == 1) {
        endPage = (startPage + maxVisiblePages - 1).clamp(startPage, totalPages);
      } else if (endPage == totalPages) {
        startPage = (endPage - maxVisiblePages + 1).clamp(1, endPage);
      }
    }

    // Add page number buttons
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageButton(context, i));
    }

    // Always show last page
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageNumbers.add(_buildEllipsis());
      }
      pageNumbers.add(_buildPageButton(context, totalPages));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(BuildContext context, int pageNumber) {
    final isCurrentPage = pageNumber == currentPage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isCurrentPage ? null : () => onPageChanged(pageNumber),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            border: Border.all(
              color: isCurrentPage
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              color: isCurrentPage
                  ? Colors.white
                  : Colors.grey[700],
              fontWeight: isCurrentPage
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// A simpler version of pagination controls with just previous/next buttons
/// for use in tight spaces or minimal pagination requirements
class SimplePaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const SimplePaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
    this.padding,
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: borderColor ?? Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: currentPage > 1 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
          ),

          // Page info
          Expanded(
            child: Center(
              child: Text(
                '${currentPage}/${totalPages}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Next button
          IconButton(
            onPressed: currentPage < totalPages ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}

/// A pagination mixin that provides standard pagination interface for Cubits
mixin PaginationMixin<T> on Cubit<T> {
  int get currentPage;
  int get totalPages;
  int get itemsPerPage;
  int get totalItems;

  Future<void> goToPage(int page);
  Future<void> nextPage();
  Future<void> previousPage();
  Future<void> changeItemsPerPage(int itemsPerPage);
}