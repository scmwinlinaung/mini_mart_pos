import '../models/purchases.dart';
import '../models/product.dart';
import '../../core/services/database_service.dart';
import '../services/purchase_database_service.dart';

class PurchaseRepository {
  final PurchaseDatabaseService _purchaseDbService;

  PurchaseRepository(DatabaseService dbService) : _purchaseDbService = PurchaseDatabaseService(dbService);

  Future<List<PurchaseWithItems>> getPurchases() async {
    try {
      // Get purchases with supplier and user information
      final purchasesData = await _purchaseDbService.getAllPurchases();
      List<PurchaseWithItems> purchasesWithItems = [];

      for (final purchaseData in purchasesData) {
        final purchase = Purchase.fromMap({
          'purchase_id': purchaseData['purchase_id'],
          'supplier_id': purchaseData['supplier_id'],
          'supplier_name': purchaseData['supplier_name'],
          'user_id': purchaseData['user_id'],
          'user_name': purchaseData['user_name'],
          'supplier_invoice_no': purchaseData['supplier_invoice_no'],
          'total_amount': purchaseData['total_amount'],
          'status': purchaseData['status'],
          'purchase_date': purchaseData['purchase_date'].toString(),
          'created_at': purchaseData['created_at']?.toString() ?? purchaseData['purchase_date'].toString(),
        });

        // Get purchase items
        final itemsData = await _purchaseDbService.getPurchaseItems(purchase.purchaseId);
        final items = itemsData.map((itemData) {
          return PurchaseItem.fromMap({
            'item_id': itemData['item_id'],
            'purchase_id': itemData['purchase_id'],
            'product_id': itemData['product_id'],
            'product_name': itemData['product_name'],
            'barcode': itemData['barcode'],
            'quantity': itemData['quantity'],
            'buy_price': itemData['buy_price'],
            'expiry_date': itemData['expiry_date']?.toString(),
          });
        }).toList();

        // Get supplier info
        final supplierData = await _purchaseDbService.getSupplierById(purchase.supplierId);
        Supplier? supplier;
        if (supplierData != null) {
          supplier = Supplier.fromMap({
            'supplier_id': supplierData['supplier_id'],
            'company_name': supplierData['company_name'],
            'contact_name': supplierData['contact_name'],
            'phone_number': supplierData['phone_number'],
            'email': supplierData['email'],
            'address': supplierData['address'],
          });
        }

        purchasesWithItems.add(
          PurchaseWithItems(
            purchase: purchase,
            items: items,
            supplier: supplier,
          ),
        );
      }

      return purchasesWithItems;
    } catch (e) {
      throw Exception('Failed to fetch purchases: $e');
    }
  }

  Future<int> createPurchase({
    required int supplierId,
    required int userId,
    String? supplierInvoiceNo,
    required int totalAmount,
    required PurchaseStatus status,
    required DateTime purchaseDate,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      return await _purchaseDbService.createPurchase(
        supplierId: supplierId,
        userId: userId,
        supplierInvoiceNo: supplierInvoiceNo,
        totalAmount: totalAmount,
        status: status.name.toUpperCase(),
        purchaseDate: purchaseDate,
        items: items,
      );
    } catch (e) {
      throw Exception('Failed to create purchase: $e');
    }
  }

  Future<void> updatePurchaseStatus(
    int purchaseId,
    PurchaseStatus status,
  ) async {
    try {
      await _purchaseDbService.updatePurchaseStatus(purchaseId, status.name.toUpperCase());
    } catch (e) {
      throw Exception('Failed to update purchase status: $e');
    }
  }

  Future<void> deletePurchase(int purchaseId) async {
    try {
      await _purchaseDbService.deletePurchase(purchaseId);
    } catch (e) {
      throw Exception('Failed to delete purchase: $e');
    }
  }

  Future<List<Supplier>> getSuppliers() async {
    try {
      final suppliersData = await _purchaseDbService.getAllSuppliers();
      return suppliersData.map((supplierData) {
        return Supplier.fromMap({
          'supplier_id': supplierData['supplier_id'],
          'company_name': supplierData['company_name'],
          'contact_name': supplierData['contact_name'],
          'phone_number': supplierData['phone_number'],
          'email': supplierData['email'],
          'address': supplierData['address'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch suppliers: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final productsData = await _purchaseDbService.getAllProducts();
      return productsData.map((productData) {
        return Product.fromMap({
          'product_id': productData['product_id'],
          'category_id': productData['category_id'],
          'supplier_id': productData['supplier_id'],
          'unit_type_id': productData['unit_type_id'],
          'barcode': productData['barcode'],
          'product_name': productData['product_name'],
          'description': productData['description'],
          'cost_price': productData['cost_price'],
          'sell_price': productData['sell_price'],
          'stock_quantity': productData['stock_quantity'],
          'reorder_level': productData['reorder_level'],
          'created_at': productData['created_at'].toString(),
          'updated_at': productData['updated_at'].toString(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }
}
