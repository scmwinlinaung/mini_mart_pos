/// Example usage of InvoiceService throughout the project
///
/// This file demonstrates how to use the InvoiceService
/// to generate sequential invoice numbers.

import 'package:mini_mart_pos/core/services/database_service.dart';
import 'package:mini_mart_pos/core/services/invoice_service.dart';

/// Example 1: Using InvoiceService in a Repository
///
/// This is the recommended pattern for repositories that need to generate invoices.
class ExampleRepository {
  final DatabaseService _dbService;
  late final InvoiceService _invoiceService;

  ExampleRepository(this._dbService) {
    _invoiceService = InvoiceService(_dbService);
  }

  Future<void> createSale() async {
    // Generate next sequential invoice number
    final invoiceNo = await _invoiceService.generateNextInvoiceNumber();
    // Result: INV-000000001, INV-000000002, etc.

    // Use the invoice number in your transaction
    // ... database insert logic here
  }
}

/// Example 2: Using InvoiceService Standalone
///
/// You can also create an instance wherever needed.
Future<String> generateInvoiceNumber(DatabaseService dbService) async {
  final invoiceService = InvoiceService(dbService);
  return await invoiceService.generateNextInvoiceNumber();
}

/// Example 3: Generate Multiple Invoice Numbers (Batch)
///
/// Useful for bulk operations or imports.
Future<List<String>> generateBulkInvoices(DatabaseService dbService, int count) async {
  final invoiceService = InvoiceService(dbService);
  return await invoiceService.generateInvoiceNumbers(count);
  // Returns: [INV-000000001, INV-000000002, INV-000000003, ...]
}

/// Example 4: Parse and Validate Invoice Numbers
///
/// Useful for reporting or validation.
void validateInvoice(String invoiceNo) {
  // Check if format is valid
  if (InvoiceService.isValidInvoiceNumber(invoiceNo)) {
    print('Valid invoice number: $invoiceNo');

    // Extract numeric part
    final number = InvoiceService.parseInvoiceNumber(invoiceNo);
    print('Invoice number: $number');
  } else {
    print('Invalid invoice number format');
  }
}

/// Example 5: Format for Display
///
/// Ensure consistent formatting in UI.
String formatInvoiceForDisplay(String invoiceNo) {
  return InvoiceService.formatForDisplay(invoiceNo);
}

/*
 * INVOICE NUMBER FORMAT:
 * - Prefix: INV-
 * - Digits: 9 digits, zero-padded
 * - Examples: INV-000000001, INV-000000123, INV-000001234
 *
 * BENEFITS:
 * - Sequential and easy to sort
 * - Human-readable
 * - Fixed length for database efficiency
 * - Easy to parse and validate
 * - Thread-safe (uses database locking)
 */
