import '../../core/services/database_service.dart';
import '../models/product.dart';

class SupplierDatabaseService {
  final DatabaseService _databaseService;

  SupplierDatabaseService(this._databaseService);

  Future<List<Supplier>> getAllSuppliers({int page = 1, int limit = 10}) async {
    final conn = await _databaseService.connection;
    final offset = (page - 1) * limit;

    final result = await conn.execute(
      '''
      SELECT
        s.*,
        COUNT(p.product_id) as product_count
      FROM suppliers s
      LEFT JOIN products p ON s.supplier_id = p.supplier_id AND p.is_active = true
      WHERE s.is_active = true
      GROUP BY s.supplier_id, s.company_name, s.contact_name, s.phone_number, s.email, s.address, s.created_at, s.updated_at
      ORDER BY s.company_name
      LIMIT \$1 OFFSET \$2
    ''',
      parameters: [limit, offset],
    );

    return result.map((row) {
      final supplierId = row[0] as int;
      final companyName = row[1] as String;
      final contactName = row[2] as String?;
      final phoneNumber = row[3] as String?;
      final email = row[4] as String?;
      final address = row[5] as String?;

      return Supplier(
        supplierId: supplierId,
        companyName: companyName,
        contactName: contactName,
        phoneNumber: phoneNumber,
        email: email,
        address: address,
      );
    }).toList();
  }

  // Get total count of active suppliers for pagination
  Future<int> getSuppliersCount() async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT COUNT(*) as count FROM suppliers WHERE is_active = true',
    );
    return result.first[0] as int;
  }

  Future<Supplier?> getSupplierById(int supplierId) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT * FROM suppliers WHERE supplier_id = \$1',
      parameters: [supplierId],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return Supplier(
      supplierId: row[0] as int,
      companyName: row[1] as String,
      contactName: row[2] as String?,
      phoneNumber: row[3] as String?,
      email: row[4] as String?,
      address: row[5] as String?,
    );
  }

  Future<List<Supplier>> searchSuppliers(String searchTerm) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      '''SELECT * FROM suppliers
         WHERE is_active = true AND (
           company_name ILIKE \$1 OR
           contact_name ILIKE \$1 OR
           email ILIKE \$1 OR
           phone_number ILIKE \$1
         ) ORDER BY company_name''',
      parameters: ['%$searchTerm%'],
    );

    return result.map((row) {
      final supplierId = row[0] as int;
      final companyName = row[1] as String;
      final contactName = row[2] as String?;
      final phoneNumber = row[3] as String?;
      final email = row[4] as String?;
      final address = row[5] as String?;

      return Supplier(
        supplierId: supplierId,
        companyName: companyName,
        contactName: contactName,
        phoneNumber: phoneNumber,
        email: email,
        address: address,
      );
    }).toList();
  }

  Future<int> createSupplier({
    required String companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
  }) async {
    // Validate inputs
    _validateSupplierData(
      companyName: companyName,
      contactName: contactName,
      phoneNumber: phoneNumber,
      email: email,
      address: address,
    );

    final conn = await _databaseService.connection;
    final result = await conn.execute(
      '''INSERT INTO suppliers (company_name, contact_name, phone_number, email, address, created_at)
         VALUES (\$1, \$2, \$3, \$4, \$5, NOW()) RETURNING supplier_id''',
      parameters: [companyName, contactName, phoneNumber, email, address],
    );

    return result.first[0] as int;
  }

  Future<void> updateSupplier(
    int supplierId, {
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
  }) async {
    // Validate inputs
    _validateSupplierData(
      companyName: companyName,
      contactName: contactName,
      phoneNumber: phoneNumber,
      email: email,
      address: address,
    );

    final conn = await _databaseService.connection;

    final updates = <String>[];
    final values = <dynamic>[];
    var paramIndex = 1;

    if (companyName != null) {
      updates.add('company_name = \$$paramIndex');
      values.add(companyName);
      paramIndex++;
    }

    if (contactName != null) {
      updates.add('contact_name = \$$paramIndex');
      values.add(contactName);
      paramIndex++;
    }

    if (phoneNumber != null) {
      updates.add('phone_number = \$$paramIndex');
      values.add(phoneNumber);
      paramIndex++;
    }

    if (email != null) {
      updates.add('email = \$$paramIndex');
      values.add(email);
      paramIndex++;
    }

    if (address != null) {
      updates.add('address = \$$paramIndex');
      values.add(address);
      paramIndex++;
    }

    if (updates.isEmpty) return;

    updates.add('updated_at = NOW()');
    values.add(supplierId);

    final query =
        'UPDATE suppliers SET ${updates.join(', ')} WHERE supplier_id = \$$paramIndex';
    await conn.execute(query, parameters: values);
  }

  Future<void> deleteSupplier(int supplierId) async {
    final conn = await _databaseService.connection;
    await conn.execute(
      'delete from suppliers WHERE supplier_id = \$1',
      parameters: [supplierId],
    );
  }

  Future<bool> canDeleteSupplier(int supplierId) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT COUNT(*) as count FROM products WHERE supplier_id = \$1 AND is_active = true',
      parameters: [supplierId],
    );

    return (result.first[0] as int) == 0;
  }

  Future<Map<String, dynamic>> getAllSupplierStatistics() async {
    final conn = await _databaseService.connection;

    // Basic supplier count
    final supplierCountResult = await conn.execute(
      'SELECT COUNT(*) as count FROM suppliers WHERE is_active = true',
    );
    final supplierCount = supplierCountResult.first[0] as int;

    // Complete statistics for all suppliers
    final allSuppliersResult = await conn.execute('''SELECT
         s.supplier_id,
         s.company_name,
         COUNT(p.product_id) as product_count,
         COALESCE(SUM(p.stock_quantity * p.cost_price), 0) as total_value,
         COALESCE(SUM(CASE WHEN p.stock_quantity <= p.reorder_level THEN 1 ELSE 0 END), 0) as low_stock_count
         FROM suppliers s
         LEFT JOIN products p ON s.supplier_id = p.supplier_id AND p.is_active = true
         WHERE s.is_active = true
         GROUP BY s.supplier_id, s.company_name
         ORDER BY s.company_name''');

    final supplierStats = allSuppliersResult
        .map(
          (row) => {
            'supplierId': row[0] as int,
            'companyName': row[1] as String,
            'productCount': row[2] as int,
            'totalValue': (row[3] as int?)?.toDouble() ?? 0.0,
            'lowStockCount': row[4] as int,
          },
        )
        .toList();
    return {
      'supplierStatistics': supplierStats,
      'totalSuppliers': supplierCount,
    };
  }

  Future<Map<String, dynamic>> getSupplierStatistics(int supplierId) async {
    final conn = await _databaseService.connection;

    // Product count
    final productCountResult = await conn.execute(
      'SELECT COUNT(*) as count FROM products WHERE supplier_id = \$1 AND is_active = true',
      parameters: [supplierId],
    );

    // Total products value
    final totalValueResult = await conn.execute(
      '''SELECT SUM(stock_quantity * cost_price) as total_value
         FROM products WHERE supplier_id = \$1 AND is_active = true''',
      parameters: [supplierId],
    );

    return {
      'product_count': productCountResult.first[0] as int,
      'total_value': (totalValueResult.first[0] as int?) ?? 0,
    };
  }

  void _validateSupplierData({
    String? companyName,
    String? contactName,
    String? phoneNumber,
    String? email,
    String? address,
  }) {
    // Company name validation
    if (companyName != null) {
      if (companyName.trim().isEmpty) {
        throw Exception('Company name is required');
      }
      if (companyName.length > 100) {
        throw Exception('Company name must be less than 100 characters');
      }
      if (!RegExp(r'^[a-zA-Z0-9\s\-&().,]+$').hasMatch(companyName)) {
        throw Exception(
          'Company name can only contain letters, numbers, spaces, and common symbols',
        );
      }
    }

    // Contact name validation
    if (contactName != null && contactName.isNotEmpty) {
      if (contactName.length > 100) {
        throw Exception('Contact name must be less than 100 characters');
      }
      if (!RegExp(r'^[a-zA-Z\s\.\-\x27]+$').hasMatch(contactName)) {
        throw Exception(
          'Contact name can only contain letters, spaces, and common name symbols',
        );
      }
    }

    // Phone number validation
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (phoneNumber.length > 20) {
        throw Exception('Phone number must be less than 20 characters');
      }
      if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phoneNumber)) {
        throw Exception(
          'Phone number can only contain digits, spaces, and common phone symbols',
        );
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
    if (address != null && address.isNotEmpty && address.length > 500) {
      throw Exception('Address must be less than 500 characters');
    }
  }

  // Validation methods
  Future<bool> isCompanyNameTaken(
    String companyName, {
    int? excludeSupplierId,
  }) async {
    final conn = await _databaseService.connection;

    String query =
        'SELECT COUNT(*) as count FROM suppliers WHERE company_name = \$1 AND is_active = true';
    final values = <dynamic>[companyName];

    if (excludeSupplierId != null) {
      query += ' AND supplier_id != \$2';
      values.add(excludeSupplierId);
    }

    final result = await conn.execute(query, parameters: values);
    return (result.first[0] as int) > 0;
  }

  Future<bool> isEmailTaken(String email, {int? excludeSupplierId}) async {
    final conn = await _databaseService.connection;

    String query =
        'SELECT COUNT(*) as count FROM suppliers WHERE email = \$1 AND is_active = true';
    final values = <dynamic>[email];

    if (excludeSupplierId != null) {
      query += ' AND supplier_id != \$2';
      values.add(excludeSupplierId);
    }

    final result = await conn.execute(query, parameters: values);
    return (result.first[0] as int) > 0;
  }

  Future<List<Supplier>> getActiveSuppliers() async {
    return await getAllSuppliers();
  }

  Future<List<Supplier>> getSuppliersWithLowStock() async {
    // This would typically join with products table to find suppliers with low stock products
    // For now, return all active suppliers
    return await getAllSuppliers();
  }
}
