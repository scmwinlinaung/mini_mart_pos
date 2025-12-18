import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/purchases.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../core/service_locator.dart';

// Events
abstract class PurchaseEvent extends Equatable {
  const PurchaseEvent();

  @override
  List<Object?> get props => [];
}

class LoadPurchases extends PurchaseEvent {}

class AddPurchase extends PurchaseEvent {
  final Map<String, dynamic> purchaseData;
  final List<Map<String, dynamic>> itemsData;

  const AddPurchase(this.purchaseData, this.itemsData);

  @override
  List<Object?> get props => [purchaseData, itemsData];
}

class UpdatePurchaseStatus extends PurchaseEvent {
  final int purchaseId;
  final PurchaseStatus status;

  const UpdatePurchaseStatus(this.purchaseId, this.status);

  @override
  List<Object?> get props => [purchaseId, status];
}

class SearchPurchases extends PurchaseEvent {
  final String query;

  const SearchPurchases(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterPurchases extends PurchaseEvent {
  final PurchaseStatus? status;

  const FilterPurchases(this.status);

  @override
  List<Object?> get props => [status];
}

class DeletePurchase extends PurchaseEvent {
  final int purchaseId;

  const DeletePurchase(this.purchaseId);

  @override
  List<Object?> get props => [purchaseId];
}

// States
abstract class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object?> get props => [];
}

class PurchaseInitial extends PurchaseState {}

class PurchaseLoading extends PurchaseState {}

class PurchaseLoaded extends PurchaseState {
  final List<PurchaseWithItems> purchases;
  final List<PurchaseWithItems> filteredPurchases;
  final String searchQuery;
  final PurchaseStatus? statusFilter;
  final bool isLoading;

  const PurchaseLoaded({
    required this.purchases,
    required this.filteredPurchases,
    this.searchQuery = '',
    this.statusFilter,
    this.isLoading = false,
  });

  PurchaseLoaded copyWith({
    List<PurchaseWithItems>? purchases,
    List<PurchaseWithItems>? filteredPurchases,
    String? searchQuery,
    PurchaseStatus? statusFilter,
    bool? isLoading,
  }) {
    return PurchaseLoaded(
      purchases: purchases ?? this.purchases,
      filteredPurchases: filteredPurchases ?? this.filteredPurchases,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        purchases,
        filteredPurchases,
        searchQuery,
        statusFilter,
        isLoading,
      ];
}

class PurchaseError extends PurchaseState {
  final String message;

  const PurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC/Cubit
class PurchaseCubit extends Cubit<PurchaseState> {
  final PurchaseRepository _purchaseRepository;

  PurchaseCubit() : _purchaseRepository = sl<PurchaseRepository>(), super(PurchaseInitial());

  Future<void> loadPurchases() async {
    try {
      emit(PurchaseLoading());
      final purchases = await _purchaseRepository.getPurchases();

      emit(PurchaseLoaded(
        purchases: purchases,
        filteredPurchases: purchases,
      ));
    } catch (e) {
      emit(PurchaseError('Failed to load purchases: ${e.toString()}'));
    }
  }

  Future<void> addPurchase(Map<String, dynamic> purchaseData, List<Map<String, dynamic>> itemsData) async {
    try {
      emit(state is PurchaseLoaded
          ? (state as PurchaseLoaded).copyWith(isLoading: true)
          : PurchaseLoading());

      await _purchaseRepository.createPurchase(
        supplierId: purchaseData['supplier_id'],
        userId: purchaseData['user_id'],
        supplierInvoiceNo: purchaseData['supplier_invoice_no'],
        totalAmount: purchaseData['total_amount'],
        status: PurchaseStatus.values.firstWhere((status) =>
            status.toString().split('.').last.toLowerCase() == purchaseData['status'].toString().toLowerCase(),
            orElse: () => PurchaseStatus.pending),
        purchaseDate: purchaseData['purchase_date'] ?? DateTime.now(),
        items: itemsData,
      );

      // Reload the purchases to get updated data
      await loadPurchases();
    } catch (e) {
      emit(PurchaseError('Failed to add purchase: ${e.toString()}'));
    }
  }

  Future<void> updatePurchaseStatus(int purchaseId, PurchaseStatus status) async {
    try {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(isLoading: true));
      }

      await _purchaseRepository.updatePurchaseStatus(purchaseId, status);

      // Reload the purchases to get updated data
      await loadPurchases();
    } catch (e) {
      emit(PurchaseError('Failed to update purchase status: ${e.toString()}'));
    }
  }

  Future<void> deletePurchase(int purchaseId) async {
    try {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(isLoading: true));
      }

      await _purchaseRepository.deletePurchase(purchaseId);

      // Reload the purchases to get updated data
      await loadPurchases();
    } catch (e) {
      emit(PurchaseError('Failed to delete purchase: ${e.toString()}'));
    }
  }

  void searchPurchases(String query) {
    if (state is PurchaseLoaded) {
      final currentState = state as PurchaseLoaded;
      final filtered = _applyFiltersAndSearch(
        currentState.purchases,
        query,
        currentState.statusFilter,
      );

      emit(currentState.copyWith(
        filteredPurchases: filtered,
        searchQuery: query,
      ));
    }
  }

  void filterPurchases(PurchaseStatus? status) {
    if (state is PurchaseLoaded) {
      final currentState = state as PurchaseLoaded;
      final filtered = _applyFiltersAndSearch(
        currentState.purchases,
        currentState.searchQuery,
        status,
      );

      emit(currentState.copyWith(
        filteredPurchases: filtered,
        statusFilter: status,
      ));
    }
  }

  List<PurchaseWithItems> _applyFiltersAndSearch(
    List<PurchaseWithItems> purchases,
    String searchQuery,
    PurchaseStatus? statusFilter,
  ) {
    var filtered = purchases;

    // Apply status filter
    if (statusFilter != null) {
      filtered = filtered.where((p) => p.purchase.status == statusFilter).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((purchase) {
        final matchesSupplier = purchase.purchase.supplierName?.toLowerCase().contains(query) ?? false;
        final matchesInvoice = purchase.purchase.supplierInvoiceNo?.toLowerCase().contains(query) ?? false;
        final matchesId = purchase.purchase.purchaseId.toString().contains(query);

        return matchesSupplier || matchesInvoice || matchesId;
      }).toList();
    }

    return filtered;
  }

  void clearError() {
    if (state is PurchaseError) {
      emit(PurchaseInitial());
    }
  }
}