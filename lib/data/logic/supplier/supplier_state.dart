part of 'supplier_cubit.dart';

class SupplierState {
  final List<Supplier> suppliers;
  final Supplier? selectedSupplier;
  final bool isLoading;
  final String? error;
  final bool isEditing;
  final List<Map<String, dynamic>> supplierStatistics;

  // Pagination
  final int currentPage;
  final int totalPages;
  final int totalSuppliersCount;
  final int pageSize;

  // Form fields
  final String companyName;
  final String contactName;
  final String phoneNumber;
  final String email;
  final String address;

  // Form errors
  final String? companyNameError;
  final String? contactNameError;
  final String? phoneNumberError;
  final String? emailError;
  final String? addressError;

  // Search state
  final String searchTerm;
  final bool isSearching;

  // Statistics loading
  final bool isLoadingStatistics;

  const SupplierState({
    this.suppliers = const [],
    this.selectedSupplier,
    this.isLoading = false,
    this.error,
    this.isEditing = false,
    this.supplierStatistics = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalSuppliersCount = 0,
    this.pageSize = 20,
    this.companyName = '',
    this.contactName = '',
    this.phoneNumber = '',
    this.email = '',
    this.address = '',
    this.companyNameError,
    this.contactNameError,
    this.phoneNumberError,
    this.emailError,
    this.addressError,
    this.searchTerm = '',
    this.isSearching = false,
    this.isLoadingStatistics = false,
  });

  SupplierState copyWith({
    List<Supplier>? suppliers,
    Supplier? selectedSupplier,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isEditing,
    List<Map<String, dynamic>>? supplierStatistics,
    int? currentPage,
    int? totalPages,
    int? totalSuppliersCount,
    int? pageSize,
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
    String? companyNameError,
    String? contactNameError,
    String? phoneNumberError,
    String? emailError,
    String? addressError,
    String? searchTerm,
    bool? isSearching,
    bool? isLoadingStatistics,
    bool clearCompanyNameError = false,
    bool clearContactNameError = false,
    bool clearPhoneNumberError = false,
    bool clearEmailError = false,
    bool clearAddressError = false,
    bool clearAllErrors = false,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      selectedSupplier: selectedSupplier ?? this.selectedSupplier,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isEditing: isEditing ?? this.isEditing,
      supplierStatistics: supplierStatistics ?? this.supplierStatistics,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalSuppliersCount: totalSuppliersCount ?? this.totalSuppliersCount,
      pageSize: pageSize ?? this.pageSize,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      companyNameError: clearCompanyNameError || clearAllErrors ? null : (companyNameError ?? this.companyNameError),
      contactNameError: clearContactNameError || clearAllErrors ? null : (contactNameError ?? this.contactNameError),
      phoneNumberError: clearPhoneNumberError || clearAllErrors ? null : (phoneNumberError ?? this.phoneNumberError),
      emailError: clearEmailError || clearAllErrors ? null : (emailError ?? this.emailError),
      addressError: clearAddressError || clearAllErrors ? null : (addressError ?? this.addressError),
      searchTerm: searchTerm ?? this.searchTerm,
      isSearching: isSearching ?? this.isSearching,
      isLoadingStatistics: isLoadingStatistics ?? this.isLoadingStatistics,
    );
  }

  bool get isFormValid {
    return companyName.isNotEmpty &&
        companyNameError == null &&
        contactNameError == null &&
        phoneNumberError == null &&
        emailError == null &&
        addressError == null;
  }

  List<Supplier> get filteredSuppliers {
    if (searchTerm.isEmpty) {
      return suppliers;
    }

    return suppliers.where((supplier) {
      return supplier.companyName.toLowerCase().contains(searchTerm.toLowerCase()) ||
          (supplier.contactName?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
          (supplier.email?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
          (supplier.phoneNumber?.contains(searchTerm) ?? false);
    }).toList();
  }

  // Keep the old getter for backward compatibility in statistics
  @Deprecated('Use totalSuppliersCount for pagination, suppliers.length for current page')
  int get totalSuppliers {
    return suppliers.length;
  }

  int get totalProducts {
    return supplierStatistics.fold(0, (sum, stat) => sum + (stat['productCount'] as int? ?? 0));
  }

  int get suppliersWithProducts {
    return supplierStatistics.where((stat) => (stat['productCount'] as int? ?? 0) > 0).length;
  }

  double get totalInventoryValue {
    return supplierStatistics.fold(0.0, (sum, stat) => sum + (stat['totalValue'] as double? ?? 0.0));
  }

  int get totalLowStockItems {
    return supplierStatistics.fold(0, (sum, stat) => sum + (stat['lowStockCount'] as int? ?? 0));
  }
}