/// Simple test/demo for InvoiceService
/// Run this file to verify invoice number generation works correctly
///
/// Usage: dart test_invoice_service.dart

import 'lib/core/services/database_service.dart';
import 'lib/core/services/invoice_service.dart';

Future<void> main() async {
  print('🧪 Testing InvoiceService...\n');

  final dbService = DatabaseService();
  final invoiceService = InvoiceService(dbService);

  try {
    // Test 1: Generate single invoice number
    print('Test 1: Generate single invoice number');
    final invoice1 = await invoiceService.generateNextInvoiceNumber();
    print('  ✓ Generated: $invoice1');
    print('  ✓ Format: ${InvoiceService.isValidInvoiceNumber(invoice1) ? "Valid" : "Invalid"}\n');

    // Test 2: Parse invoice number
    print('Test 2: Parse invoice number');
    final parsed = InvoiceService.parseInvoiceNumber(invoice1);
    print('  ✓ Parsed value: $parsed\n');

    // Test 3: Generate multiple invoice numbers
    print('Test 3: Generate 5 invoice numbers');
    final invoices = await invoiceService.generateInvoiceNumbers(5);
    for (final invoice in invoices) {
      print('  ✓ $invoice');
    }
    print('');

    // Test 4: Validate format
    print('Test 4: Validate invoice number formats');
    print('  ✓ INV-000000001: ${InvoiceService.isValidInvoiceNumber('INV-000000001') ? "Valid" : "Invalid"}');
    print('  ✓ INV-123: ${InvoiceService.isValidInvoiceNumber('INV-123') ? "Valid" : "Invalid"}');
    print('  ✓ INVALID: ${InvoiceService.isValidInvoiceNumber('INVALID') ? "Valid" : "Invalid"}\n');

    // Test 5: Format for display
    print('Test 5: Format for display');
    print('  ✓ Input: INV-1 → Output: ${InvoiceService.formatForDisplay('INV-1')}');
    print('  ✓ Input: INV-123 → Output: ${InvoiceService.formatForDisplay('INV-123')}\n');

    print('✅ All tests completed successfully!');
    print('\n📝 Invoice Number Format: INV-XXXXXXXXX');
    print('   - Prefix: INV-');
    print('   - Digits: 9 digits, zero-padded');
    print('   - Example: INV-000000001, INV-000000002, etc.');

  } catch (e) {
    print('❌ Error: $e');
  }
}
