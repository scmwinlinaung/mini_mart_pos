import '../models/product.dart';
import '../services/supplier_database_service.dart';
import '../../core/services/database_service.dart';

class SupplierRepository {
  final SupplierDatabaseService _supplierDbService;

  SupplierRepository(DatabaseService dbService) : _supplierDbService = SupplierDatabaseService(dbService);

  // CRUD Operations
  Future<List<Supplier>> getAllSuppliers({int page = 1, int limit = 20}) async {
    try {
      return await _supplierDbService.getAllSuppliers(page: page, limit: limit);
    } catch (e) {
      throw Exception('Failed to fetch suppliers: $e');
    }
  }

  // Get total count of suppliers for pagination
  Future<int> getSuppliersCount() async {
    try {
      return await _supplierDbService.getSuppliersCount();
    } catch (e) {
      throw Exception('Failed to fetch suppliers count: $e');
    }
  }

  Future<Supplier?> getSupplierById(int supplierId) async {
    try {
      return await _supplierDbService.getSupplierById(supplierId);
    } catch (e) {
      throw Exception('Failed to fetch supplier: $e');
    }
  }

  Future<int> createSupplier({
    required String companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
  }) async {
    try {
      // Validate input
      await _validateSupplierData(
        companyName: companyName,
        contactName: contactName,
        phoneNumber: phoneNumber,
        email: email,
        address: address,
      );

      // Check if company name is already taken
      final isCompanyNameTaken = await _supplierDbService.isCompanyNameTaken(companyName);
      if (isCompanyNameTaken) {
        throw Exception('Company name already exists');
      }

      // Check if email is already taken
      if (email != null && email.isNotEmpty) {
        final isEmailTaken = await _supplierDbService.isEmailTaken(email);
        if (isEmailTaken) {
          throw Exception('Email already exists');
        }
      }

      return await _supplierDbService.createSupplier(
        companyName: companyName.trim(),
        contactName: contactName?.trim(),
        phoneNumber: phoneNumber?.trim(),
        email: email?.trim().toLowerCase(),
        address: address?.trim(),
      );
    } catch (e) {
      throw Exception('Failed to create supplier: $e');
    }
  }

  Future<bool> updateSupplier(
    int supplierId, {
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
  }) async {
    try {
      // Validate input if provided
      if (companyName != null || contactName != null || phoneNumber != null ||
          email != null || address != null) {
        final existingSupplier = await _supplierDbService.getSupplierById(supplierId);
        if (existingSupplier == null) {
          throw Exception('Supplier not found');
        }

        await _validateSupplierData(
          companyName: companyName ?? existingSupplier.companyName,
          contactName: contactName ?? existingSupplier.contactName,
          phoneNumber: phoneNumber ?? existingSupplier.phoneNumber,
          email: email ?? existingSupplier.email,
          address: address ?? existingSupplier.address,
          isUpdate: true,
        );
      }

      // Check if company name is taken by another supplier
      if (companyName != null) {
        final isCompanyNameTaken = await _supplierDbService.isCompanyNameTaken(
          companyName,
          excludeSupplierId: supplierId,
        );
        if (isCompanyNameTaken) {
          throw Exception('Company name already exists');
        }
      }

      // Check if email is taken by another supplier
      if (email != null && email.isNotEmpty) {
        final isEmailTaken = await _supplierDbService.isEmailTaken(
          email,
          excludeSupplierId: supplierId,
        );
        if (isEmailTaken) {
          throw Exception('Email already exists');
        }
      }

      await _supplierDbService.updateSupplier(
        supplierId,
        companyName: companyName?.trim(),
        contactName: contactName?.trim(),
        phoneNumber: phoneNumber?.trim(),
        email: email?.trim().toLowerCase(),
        address: address?.trim(),
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update supplier: $e');
    }
  }

  Future<bool> deleteSupplier(int supplierId) async {
    try {
      await _supplierDbService.deleteSupplier(supplierId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }

  // Search Operations
  Future<List<Supplier>> searchSuppliers(String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return getAllSuppliers(page: 1, limit: 20);
      }

      return await _supplierDbService.searchSuppliers(searchTerm.trim());
    } catch (e) {
      throw Exception('Failed to search suppliers: $e');
    }
  }

  // Business Logic
  Future<List<Supplier>> getActiveSuppliers() async {
    try {
      return await _supplierDbService.getActiveSuppliers();
    } catch (e) {
      throw Exception('Failed to fetch active suppliers: $e');
    }
  }

  Future<List<Supplier>> getSuppliersWithLowStock() async {
    try {
      return await _supplierDbService.getSuppliersWithLowStock();
    } catch (e) {
      throw Exception('Failed to fetch suppliers with low stock: $e');
    }
  }

  Future<List<Supplier>> getUnusedSuppliers() async {
    try {
      final allSuppliers = await getAllSuppliers(page: 1, limit: 1000); // Get all for this operation
      final activeSuppliers = await getActiveSuppliers();

      // Return suppliers that are not associated with any products
      return allSuppliers.where((supplier) {
        return !activeSuppliers.any((active) => active.id == supplier.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch unused suppliers: $e');
    }
  }

  Future<Map<String, dynamic>> getSupplierStatistics(int supplierId) async {
    try {
      return await _supplierDbService.getSupplierStatistics(supplierId);
    } catch (e) {
      throw Exception('Failed to fetch supplier statistics: $e');
    }
  }

  Future<Map<String, dynamic>> getAllSupplierStatistics() async {
    try {
      return await _supplierDbService.getAllSupplierStatistics();
    } catch (e) {
      throw Exception('Failed to fetch all supplier statistics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierPerformanceReport() async {
    try {
      final allStats = await getAllSupplierStatistics();
      final supplierStats = allStats['supplierStatistics'] as List<Map<String, dynamic>>;

      // Calculate additional metrics
      final report = supplierStats.map((stat) {
        final productCount = stat['productCount'] as int;
        final totalStock = stat['totalStock'] as int;
        final lowStockCount = stat['lowStockCount'] as int;
        final totalValue = stat['totalValue'] as double;

        // Calculate average stock per product
        final avgStockPerProduct = productCount > 0 ? totalStock / productCount : 0.0;

        // Calculate average value per product
        final avgValuePerProduct = productCount > 0 ? totalValue / productCount : 0.0;

        // Calculate stock health percentage
        final stockHealthPercentage = productCount > 0
            ? ((productCount - lowStockCount) / productCount) * 100
            : 100.0;

        return {
          ...stat,
          'avgStockPerProduct': avgStockPerProduct,
          'avgValuePerProduct': avgValuePerProduct,
          'stockHealthPercentage': stockHealthPercentage,
          'hasLowStock': lowStockCount > 0,
          'isEmpty': productCount == 0,
          'totalValue': totalValue,
        };
      }).toList();

      // Sort by total value descending
      report.sort((a, b) => (b['totalValue'] as double).compareTo(a['totalValue'] as double));

      return report;
    } catch (e) {
      throw Exception('Failed to generate supplier performance report: $e');
    }
  }

  Future<bool> isCompanyNameAvailable(String companyName, {int? excludeSupplierId}) async {
    try {
      return !(await _supplierDbService.isCompanyNameTaken(companyName, excludeSupplierId: excludeSupplierId));
    } catch (e) {
      throw Exception('Failed to check company name availability: $e');
    }
  }

  Future<bool> isEmailAvailable(String email, {int? excludeSupplierId}) async {
    try {
      if (email.trim().isEmpty) return true;
      return !(await _supplierDbService.isEmailTaken(email, excludeSupplierId: excludeSupplierId));
    } catch (e) {
      throw Exception('Failed to check email availability: $e');
    }
  }

  Future<bool> canDeleteSupplier(int supplierId) async {
    try {
      final stats = await _supplierDbService.getSupplierStatistics(supplierId);
      return stats['productCount'] == 0;
    } catch (e) {
      throw Exception('Failed to check if supplier can be deleted: $e');
    }
  }

  Future<int> getTotalProductCountForSupplier(int supplierId) async {
    try {
      final stats = await _supplierDbService.getSupplierStatistics(supplierId);
      return stats['productCount'] as int;
    } catch (e) {
      throw Exception('Failed to get product count for supplier: $e');
    }
  }

  Future<double> getTotalInventoryValueForSupplier(int supplierId) async {
    try {
      final stats = await _supplierDbService.getSupplierStatistics(supplierId);
      return stats['totalValue'] as double;
    } catch (e) {
      throw Exception('Failed to get inventory value for supplier: $e');
    }
  }

  // Validation
  Future<void> _validateSupplierData({
    required String companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
    bool isUpdate = false,
  }) async {
    // Company name validation
    if (companyName.trim().isEmpty) {
      throw Exception('Company name is required');
    }
    if (companyName.length > 100) {
      throw Exception('Company name must be less than 100 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-&().,]+$').hasMatch(companyName)) {
      throw Exception('Company name can only contain letters, numbers, spaces, and common symbols');
    }

    // Contact name validation
    if (contactName != null && contactName.isNotEmpty) {
      if (contactName.length > 100) {
        throw Exception('Contact name must be less than 100 characters');
      }
      if (!RegExp(r'^[a-zA-Z\s\.\-\x27]+$').hasMatch(contactName)) {
        throw Exception('Contact name can only contain letters, spaces, and common name symbols');
      }
    }

    // Phone number validation
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (phoneNumber.length > 20) {
        throw Exception('Phone number must be less than 20 characters');
      }
      if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phoneNumber)) {
        throw Exception('Phone number can only contain digits, spaces, and common phone symbols');
      }
    }

    // Email validation
    if (email != null && email.isNotEmpty) {
      if (email.length > 100) {
        throw Exception('Email must be less than 100 characters');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Invalid email format');
      }
    }

    // Address validation
    if (address != null && address.isNotEmpty) {
      if (address.length > 500) {
        throw Exception('Address must be less than 500 characters');
      }
    }
  }

  // Helper methods
  Future<List<Supplier>> getTopSuppliersByValue({int limit = 5}) async {
    try {
      final report = await getSupplierPerformanceReport();
      final topSupplierIds = report
          .where((stat) => (stat['totalValue'] as double) > 0)
          .take(limit)
          .map((stat) => stat['supplierId'] as int)
          .toList();

      final allSuppliers = await getAllSuppliers(page: 1, limit: 1000); // Get all for this operation
      return allSuppliers.where((supplier) => topSupplierIds.contains(supplier.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch top suppliers by value: $e');
    }
  }

  Future<List<Supplier>> getSuppliersNeedingAttention() async {
    try {
      return await getSuppliersWithLowStock();
    } catch (e) {
      throw Exception('Failed to fetch suppliers needing attention: $e');
    }
  }
}