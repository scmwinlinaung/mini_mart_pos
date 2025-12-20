import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../repositories/supplier_repository.dart';
import '../../../core/service_locator.dart';
import '../../../core/services/database_service.dart';

part 'supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  late final SupplierRepository _supplierRepository;

  SupplierCubit() : super(const SupplierState()) {
    _supplierRepository = SupplierRepository(sl<DatabaseService>());
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadSuppliers(),
      loadSupplierStatistics(),
    ]);
  }

  Future<void> loadSuppliers({int page = 1, int limit = 20}) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final suppliers = await _supplierRepository.getAllSuppliers(page: page, limit: limit);
      final totalCount = await _supplierRepository.getSuppliersCount();
      final totalPages = (totalCount / limit).ceil();

      emit(state.copyWith(
        suppliers: suppliers,
        currentPage: page,
        totalPages: totalPages,
        totalSuppliersCount: totalCount,
        pageSize: limit,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadSupplierStatistics() async {
    try {
      emit(state.copyWith(isLoadingStatistics: true));

      final allStats = await _supplierRepository.getAllSupplierStatistics();
      final supplierStats = allStats['supplierStatistics'] as List<Map<String, dynamic>>;

      emit(state.copyWith(
        supplierStatistics: supplierStats,
        isLoadingStatistics: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStatistics: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> searchSuppliers(String searchTerm, {int? page}) async {
    try {
      emit(state.copyWith(isSearching: true, searchTerm: searchTerm));

      if (searchTerm.trim().isEmpty) {
        await loadSuppliers();
        emit(state.copyWith(isSearching: false));
        return;
      }

      // For search, we'll get all results and update pagination accordingly
      final searchResults = await _supplierRepository.searchSuppliers(searchTerm);
      final totalCount = searchResults.length;
      final totalPages = (totalCount / state.pageSize).ceil();
      final targetPage = page ?? 1;

      // Get current page of search results
      final startIndex = (targetPage - 1) * state.pageSize;
      final currentPageResults = searchResults.skip(startIndex).take(state.pageSize).toList();

      emit(state.copyWith(
        suppliers: currentPageResults,
        currentPage: targetPage,
        totalPages: totalPages,
        totalSuppliersCount: totalCount,
        isSearching: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        error: e.toString(),
      ));
    }
  }

  void selectSupplier(Supplier? supplier) {
    if (supplier != null) {
      emit(state.copyWith(
        selectedSupplier: supplier,
        isEditing: true,
        companyName: supplier.companyName,
        contactName: supplier.contactName ?? '',
        phoneNumber: supplier.phoneNumber ?? '',
        email: supplier.email ?? '',
        address: supplier.address ?? '',
        clearAllErrors: true,
      ));
    } else {
      emit(state.copyWith(
        selectedSupplier: null,
        isEditing: false,
        companyName: '',
        contactName: '',
        phoneNumber: '',
        email: '',
        address: '',
        clearAllErrors: true,
      ));
    }
  }

  void updateCompanyName(String value) {
    emit(state.copyWith(companyName: value));
    _validateCompanyName();
  }

  void updateContactName(String value) {
    emit(state.copyWith(contactName: value));
    _validateContactName();
  }

  void updatePhoneNumber(String value) {
    emit(state.copyWith(phoneNumber: value));
    _validatePhoneNumber();
  }

  void updateEmail(String value) {
    emit(state.copyWith(email: value));
    _validateEmail();
  }

  void updateAddress(String value) {
    emit(state.copyWith(address: value));
    _validateAddress();
  }

  Future<void> saveSupplier() async {
    try {
      // Validate all fields
      if (!_validateAllFields()) {
        return;
      }

      emit(state.copyWith(isLoading: true, clearError: true));

      if (state.isEditing && state.selectedSupplier != null) {
        // Update existing supplier
        await _supplierRepository.updateSupplier(
          state.selectedSupplier!.id,
          companyName: state.companyName,
          contactName: state.contactName.isEmpty ? null : state.contactName,
          phoneNumber: state.phoneNumber.isEmpty ? null : state.phoneNumber,
          email: state.email.isEmpty ? null : state.email,
          address: state.address.isEmpty ? null : state.address,
        );
      } else {
        // Create new supplier
        await _supplierRepository.createSupplier(
          companyName: state.companyName,
          contactName: state.contactName.isEmpty ? null : state.contactName,
          phoneNumber: state.phoneNumber.isEmpty ? null : state.phoneNumber,
          email: state.email.isEmpty ? null : state.email,
          address: state.address.isEmpty ? null : state.address,
        );
      }

      // Reload suppliers and statistics, then reset form
      await loadInitialData();
      selectSupplier(null);

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteSupplier(int supplierId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _supplierRepository.deleteSupplier(supplierId);

      await loadInitialData();

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refreshData() async {
    await loadInitialData();
  }

  void clearForm() {
    selectSupplier(null);
  }

  void clearSearch() {
    emit(state.copyWith(searchTerm: ''));
    loadSuppliers();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  bool _validateAllFields() {
    var isValid = true;

    isValid &= _validateCompanyName();
    isValid &= _validateContactName();
    isValid &= _validatePhoneNumber();
    isValid &= _validateEmail();
    isValid &= _validateAddress();

    return isValid;
  }

  bool _validateCompanyName() {
    final companyName = state.companyName;
    if (companyName.trim().isEmpty) {
      emit(state.copyWith(companyNameError: 'Company name is required'));
      return false;
    }
    if (companyName.length > 100) {
      emit(state.copyWith(companyNameError: 'Company name must be less than 100 characters'));
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-&().,]+$').hasMatch(companyName)) {
      emit(state.copyWith(companyNameError: 'Company name can only contain letters, numbers, spaces, and common symbols'));
      return false;
    }

    emit(state.copyWith(clearCompanyNameError: true));
    return true;
  }

  bool _validateContactName() {
    final contactName = state.contactName;
    if (contactName.isNotEmpty) {
      if (contactName.length > 100) {
        emit(state.copyWith(contactNameError: 'Contact name must be less than 100 characters'));
        return false;
      }
      if (!RegExp(r'^[a-zA-Z\s\.\-\x27]+$').hasMatch(contactName)) {
        emit(state.copyWith(contactNameError: 'Contact name can only contain letters, spaces, and common name symbols'));
        return false;
      }
    }

    emit(state.copyWith(contactNameError: null));
    return true;
  }

  bool _validatePhoneNumber() {
    final phoneNumber = state.phoneNumber;
    if (phoneNumber.isNotEmpty) {
      if (phoneNumber.length > 20) {
        emit(state.copyWith(phoneNumberError: 'Phone number must be less than 20 characters'));
        return false;
      }
      if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phoneNumber)) {
        emit(state.copyWith(phoneNumberError: 'Phone number can only contain digits, spaces, and common phone symbols'));
        return false;
      }
    }

    emit(state.copyWith(clearPhoneNumberError: true));
    return true;
  }

  bool _validateEmail() {
    final email = state.email;
    if (email.isNotEmpty) {
      if (email.length > 100) {
        emit(state.copyWith(emailError: 'Email must be less than 100 characters'));
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        emit(state.copyWith(emailError: 'Invalid email format'));
        return false;
      }
    }

    emit(state.copyWith(clearEmailError: true));
    return true;
  }

  bool _validateAddress() {
    final address = state.address;
    if (address.isNotEmpty && address.length > 500) {
      emit(state.copyWith(addressError: 'Address must be less than 500 characters'));
      return false;
    }

    emit(state.copyWith(clearAddressError: true));
    return true;
  }

  Future<Map<String, dynamic>> getSupplierDetails(int supplierId) async {
    try {
      final supplier = await _supplierRepository.getSupplierById(supplierId);
      if (supplier == null) {
        throw Exception('Supplier not found');
      }

      final statistics = await _supplierRepository.getSupplierStatistics(supplierId);

      return {
        'supplier': supplier,
        'statistics': statistics,
      };
    } catch (e) {
      throw Exception('Failed to get supplier details: $e');
    }
  }

  Future<bool> canDeleteSupplier(int supplierId) async {
    try {
      return await _supplierRepository.canDeleteSupplier(supplierId);
    } catch (e) {
      throw Exception('Failed to check if supplier can be deleted: $e');
    }
  }

  // Pagination methods
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= state.totalPages) {
      if (state.searchTerm.isNotEmpty) {
        // If we're in search mode, re-run search with new page
        await searchSuppliers(state.searchTerm, page: page);
      } else {
        // Normal pagination
        await loadSuppliers(page: page, limit: state.pageSize);
      }
    }
  }

  Future<void> nextPage() async {
    if (state.currentPage < state.totalPages) {
      await goToPage(state.currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      await goToPage(state.currentPage - 1);
    }
  }

  Future<void> changePageSize(int newPageSize) async {
    if (state.searchTerm.isNotEmpty) {
      // If we're in search mode, re-run search with new page size
      emit(state.copyWith(pageSize: newPageSize, currentPage: 1));
      await searchSuppliers(state.searchTerm);
    } else {
      // Normal pagination
      await loadSuppliers(page: 1, limit: newPageSize);
    }
  }
}