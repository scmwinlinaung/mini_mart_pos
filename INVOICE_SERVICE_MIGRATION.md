# InvoiceService Implementation Guide

## Overview
A new `InvoiceService` has been implemented to generate sequential invoice numbers throughout the entire project. This replaces the previous timestamp-based approach.

## Invoice Number Format
- **Format**: `INV-000000001`
- **Structure**: `INV-` prefix + 9-digit zero-padded number
- **Examples**:
  - First invoice: `INV-000000001`
  - 100th invoice: `INV-000000100`
  - 1000th invoice: `INV-000001000`

## Files Created/Modified

### New Files Created:
1. **lib/core/services/invoice_service.dart**
   - Main service for generating sequential invoice numbers
   - Thread-safe implementation using database queries
   - Utility methods for parsing and validation

2. **lib/core/services/services.dart**
   - Central export file for all core services
   - Makes importing services easier

3. **lib/core/services/invoice_service_example.dart**
   - Usage examples and documentation
   - Copy patterns from here for your implementation

4. **test_invoice_service.dart**
   - Test file to verify invoice generation works correctly

### Files Modified:
1. **lib/data/repositories/pos_repository.dart**
   - Now uses `InvoiceService` instead of timestamp
   - Updated import statements
   - Integrated `InvoiceService` in constructor

## How to Use in Your Code

### Pattern 1: In a Repository (Recommended)
```dart
import 'package:mini_mart_pos/core/services/database_service.dart';
import 'package:mini_mart_pos/core/services/invoice_service.dart';

class YourRepository {
  final DatabaseService _dbService;
  late final InvoiceService _invoiceService;

  YourRepository(this._dbService) {
    _invoiceService = InvoiceService(_dbService);
  }

  Future<void> yourMethod() async {
    // Generate next invoice number
    final invoiceNo = await _invoiceService.generateNextInvoiceNumber();
    // Use invoiceNo in your database operation
  }
}
```

### Pattern 2: Standalone Usage
```dart
final invoiceService = InvoiceService(databaseService);
final invoiceNo = await invoiceService.generateNextInvoiceNumber();
```

### Pattern 3: Bulk Generation
```dart
final invoiceService = InvoiceService(databaseService);
final invoices = await invoiceService.generateInvoiceNumbers(10);
// Returns [INV-000000001, INV-000000002, ..., INV-000000010]
```

## Available Methods

### InvoiceService Class

#### `Future<String> generateNextInvoiceNumber()`
Generates the next sequential invoice number.
- Returns: String in format `INV-000000001`
- Thread-safe: Uses database to determine last number

#### `Future<List<String>> generateInvoiceNumbers(int count)`
Generates multiple sequential invoice numbers in bulk.
- Parameters: `count` - number of invoices to generate
- Returns: List of invoice strings
- Useful for bulk imports or batch operations

#### `static int? parseInvoiceNumber(String invoiceNo)`
Extracts the numeric part from an invoice number.
- Parameters: `invoiceNo` - invoice number string
- Returns: Integer value or `null` if invalid format
- Example: `parseInvoiceNumber('INV-000000123')` → `123`

#### `static bool isValidInvoiceNumber(String invoiceNo)`
Validates invoice number format.
- Parameters: `invoiceNo` - string to validate
- Returns: `true` if format is valid, `false` otherwise

#### `static String formatForDisplay(String invoiceNo)`
Formats invoice number for consistent display.
- Parameters: `invoiceNo` - invoice number string
- Returns: Formatted invoice number with zero-padding
- Example: `formatForDisplay('INV-123')` → `INV-000000123`

## Migration Checklist

If you have code that generates invoice numbers, update it to use `InvoiceService`:

- [x] `pos_repository.dart` - Updated
- [ ] Your repositories - Update using Pattern 1 above
- [ ] BLoCs/Providers - Inject repository that uses InvoiceService
- [ ] Any direct database calls - Use InvoiceService instead

## Testing

To test the invoice generation:

```bash
# Run the test file
dart test_invoice_service.dart

# Or run Flutter analyze to check for errors
flutter analyze
```

## Important Notes

1. **Thread Safety**: The service queries the database for the last invoice number, ensuring sequential ordering even with concurrent requests.

2. **First Invoice**: When the database is empty, it automatically starts from `INV-000000001`.

3. **Database Table**: The service queries the `sales` table. If you use a different table for invoices, update the query in `generateNextInvoiceNumber()`.

4. **Performance**: The service makes one database query per call. For bulk operations, use `generateInvoiceNumbers()` instead of multiple calls.

5. **Consistency**: All parts of the application should use this service to ensure invoice numbers are sequential across the entire system.

## Future Enhancements

Possible improvements:
1. Add database sequence for better performance
2. Add different invoice prefixes for different transaction types (e.g., PO- for purchases, REF- for refunds)
3. Add invoice date range (e.g., INV-2025-000001)
4. Add caching mechanism to reduce database queries

## Questions?

Refer to `lib/core/services/invoice_service_example.dart` for more usage examples.
