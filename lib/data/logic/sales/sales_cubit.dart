import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/core/service_locator.dart';
import 'package:mini_mart_pos/core/services/database_service.dart';
import 'package:mini_mart_pos/data/models/sales.dart';
import 'package:mini_mart_pos/data/repositories/pos_repository.dart';

// Sales state
class SalesState {
  final List<Sale> sales;
  final SaleWithItems? selectedSaleWithItems;
  final bool isLoading;
  final String? error;

  // Filters
  final DateTime? startDate;
  final DateTime? endDate;
  final String invoiceNoFilter;
  final String? paymentMethodFilter;

  // Pagination state
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  const SalesState({
    this.sales = const [],
    this.selectedSaleWithItems,
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
    this.invoiceNoFilter = '',
    this.paymentMethodFilter,
    this.currentPage = 1,
    this.totalPages = 1,
    this.itemsPerPage = 10,
    this.totalItems = 0,
  });

  SalesState copyWith({
    List<Sale>? sales,
    SaleWithItems? selectedSaleWithItems,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? invoiceNoFilter,
    String? paymentMethodFilter,
    int? currentPage,
    int? totalPages,
    int? itemsPerPage,
    int? totalItems,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearError = false,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      selectedSaleWithItems: selectedSaleWithItems ?? this.selectedSaleWithItems,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      invoiceNoFilter: invoiceNoFilter ?? this.invoiceNoFilter,
      paymentMethodFilter: paymentMethodFilter ?? this.paymentMethodFilter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

// Sales cubit
class SalesCubit extends Cubit<SalesState> {
  late final PosRepository _repository;

  SalesCubit() : super(const SalesState()) {
    _repository = PosRepository(sl<DatabaseService>());
  }

  // Load sales with filters
  Future<void> loadSales() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await _repository.getSalesHistory(
        page: state.currentPage,
        limit: state.itemsPerPage,
        startDate: state.startDate,
        endDate: state.endDate,
        invoiceNo: state.invoiceNoFilter.isNotEmpty ? state.invoiceNoFilter : null,
        paymentMethod: state.paymentMethodFilter,
      );

      emit(state.copyWith(
        sales: result.sales,
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Refresh sales
  Future<void> refreshSales() async {
    await loadSales();
  }

  // Search by invoice number
  Future<void> searchByInvoiceNo(String invoiceNo) async {
    emit(state.copyWith(invoiceNoFilter: invoiceNo, currentPage: 1));
    await loadSales();
  }

  // Filter by date range
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    emit(
      state.copyWith(
        startDate: start,
        endDate: end,
        currentPage: 1,
      ),
    );
    await loadSales();
  }

  // Filter by payment method
  Future<void> filterByPaymentMethod(String? paymentMethod) async {
    emit(
      state.copyWith(
        paymentMethodFilter: paymentMethod,
        currentPage: 1,
      ),
    );
    await loadSales();
  }

  // Clear all filters
  Future<void> clearFilters() async {
    emit(
      state.copyWith(
        startDate: null,
        endDate: null,
        invoiceNoFilter: '',
        paymentMethodFilter: null,
        currentPage: 1,
        clearStartDate: true,
        clearEndDate: true,
      ),
    );
    await loadSales();
  }

  // Get sale details by invoice number
  Future<void> loadSaleDetails(String invoiceNo) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final saleWithItems = await _repository.getSaleByInvoice(invoiceNo);
      emit(state.copyWith(
        selectedSaleWithItems: saleWithItems,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // Clear selected sale
  void clearSelectedSale() {
    emit(state.copyWith(selectedSaleWithItems: null));
  }

  // === PAGINATION METHODS ===

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page < 1 || page > state.totalPages) return;

    emit(state.copyWith(currentPage: page));
    await loadSales();
  }

  // Go to next page
  Future<void> nextPage() async {
    if (state.currentPage < state.totalPages) {
      await goToPage(state.currentPage + 1);
    }
  }

  // Go to previous page
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      await goToPage(state.currentPage - 1);
    }
  }

  // Change items per page
  Future<void> changeItemsPerPage(int itemsPerPage) async {
    if (itemsPerPage <= 0) return;

    emit(
      state.copyWith(
        itemsPerPage: itemsPerPage,
        currentPage: 1, // Reset to first page when changing items per page
      ),
    );
    await loadSales();
  }
}
