import 'package:postgres/postgres.dart';
import 'database_service.dart';

/// Service for generating sequential invoice numbers
/// Format: INV-000000001, INV-000000002, etc.
class InvoiceService {
  final DatabaseService _dbService;

  InvoiceService(this._dbService);

  /// Generate the next sequential invoice number
  /// Format: INV-000000001 (9 digits total, including INV- prefix)
  Future<String> generateNextInvoiceNumber() async {
    final conn = await _dbService.connection;

    // Get the last invoice number from the database
    final result = await conn.execute(
      Sql.named('''
        SELECT invoice_no
        FROM sales
        WHERE invoice_no LIKE 'INV-%'
        ORDER BY sale_id DESC
        LIMIT 1
      '''),
    );

    int nextNumber = 1;

    if (result.isNotEmpty) {
      final lastInvoiceNo = result.first[0] as String;
      // Extract the numeric part from INV-XXXXXXXXX
      final numericPart = lastInvoiceNo.replaceFirst('INV-', '');
      final lastNumber = int.tryParse(numericPart) ?? 0;
      nextNumber = lastNumber + 1;
    }

    // Format as INV-000000001 (pad with zeros to 9 digits)
    return 'INV-${nextNumber.toString().padLeft(9, '0')}';
  }

  /// Generate multiple sequential invoice numbers in batch
  /// Useful for bulk operations
  Future<List<String>> generateInvoiceNumbers(int count) async {
    if (count <= 0) return [];

    final conn = await _dbService.connection;

    // Get the last invoice number
    final result = await conn.execute(
      Sql.named('''
        SELECT invoice_no
        FROM sales
        WHERE invoice_no LIKE 'INV-%'
        ORDER BY sale_id DESC
        LIMIT 1
      '''),
    );

    int startNumber = 1;

    if (result.isNotEmpty) {
      final lastInvoiceNo = result.first[0] as String;
      final numericPart = lastInvoiceNo.replaceFirst('INV-', '');
      final lastNumber = int.tryParse(numericPart) ?? 0;
      startNumber = lastNumber + 1;
    }

    // Generate the list of invoice numbers
    final List<String> invoiceNumbers = [];
    for (int i = 0; i < count; i++) {
      final number = startNumber + i;
      invoiceNumbers.add('INV-${number.toString().padLeft(9, '0')}');
    }

    return invoiceNumbers;
  }

  /// Parse invoice number to extract the numeric part
  /// Returns null if the invoice number format is invalid
  static int? parseInvoiceNumber(String invoiceNo) {
    if (!invoiceNo.startsWith('INV-')) return null;

    final numericPart = invoiceNo.replaceFirst('INV-', '');
    return int.tryParse(numericPart);
  }

  /// Validate invoice number format
  static bool isValidInvoiceNumber(String invoiceNo) {
    return parseInvoiceNumber(invoiceNo) != null;
  }

  /// Get invoice number for display (adds formatting if needed)
  static String formatForDisplay(String invoiceNo) {
    final number = parseInvoiceNumber(invoiceNo);
    if (number == null) return invoiceNo;

    return 'INV-${number.toString().padLeft(9, '0')}';
  }
}
