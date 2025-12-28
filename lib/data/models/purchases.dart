// Purchase-related models based on database schema
import 'product.dart';

class Purchase {
  final int purchaseId;
  final int supplierId;
  final String? supplierName;
  final int userId;
  final String? userName;
  final String? supplierInvoiceNo;
  final double totalAmount;
  final PurchaseStatus status;
  final DateTime purchaseDate;
  final DateTime createdAt;

  Purchase({
    required this.purchaseId,
    required this.supplierId,
    this.supplierName,
    required this.userId,
    this.userName,
    this.supplierInvoiceNo,
    required this.totalAmount,
    this.status = PurchaseStatus.received,
    required this.purchaseDate,
    required this.createdAt,
  });

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      purchaseId: map['purchase_id'] as int,
      supplierId: map['supplier_id'] as int,
      supplierName: map['supplier_name'] as String?,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String?,
      supplierInvoiceNo: map['supplier_invoice_no'] as String?,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(map['status'] as String? ?? 'RECEIVED'),
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static PurchaseStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return PurchaseStatus.pending;
      case 'RECEIVED':
        return PurchaseStatus.received;
      case 'CANCELLED':
        return PurchaseStatus.cancelled;
      default:
        return PurchaseStatus.received;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'purchase_id': purchaseId,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'user_id': userId,
      'user_name': userName,
      'supplier_invoice_no': supplierInvoiceNo,
      'total_amount': totalAmount,
      'status': status.name.toUpperCase(),
      'purchase_date': purchaseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get supplierDisplay => supplierName ?? 'Unknown Supplier';
  String get invoiceDisplay => supplierInvoiceNo ?? 'No Invoice #';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Purchase &&
          runtimeType == other.runtimeType &&
          purchaseId == other.purchaseId;

  @override
  int get hashCode => purchaseId.hashCode;

  @override
  String toString() {
    return 'Purchase{purchaseId: $purchaseId, supplier: $supplierDisplay, total: $formattedTotalAmount}';
  }
}

class PurchaseItem {
  final int itemId;
  final int purchaseId;
  final int productId;
  final String? productName;
  final String? barcode;
  final int quantity;
  final double buyPrice; // Cost per unit
  final DateTime? expiryDate;

  PurchaseItem({
    required this.itemId,
    required this.purchaseId,
    required this.productId,
    this.productName,
    this.barcode,
    required this.quantity,
    required this.buyPrice,
    this.expiryDate,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      itemId: map['item_id'] as int,
      purchaseId: map['purchase_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      barcode: map['barcode'] as String?,
      quantity: map['quantity'] as int,
      buyPrice: (map['buy_price'] as num).toDouble(),
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'barcode': barcode,
      'quantity': quantity,
      'buy_price': buyPrice,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  // Helper getters for UI
  String get formattedBuyPrice => '\$${buyPrice.toStringAsFixed(2)}';
  double get total => buyPrice * quantity;
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get expiryDisplay => expiryDate != null
      ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
      : 'No expiry';
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId;

  @override
  int get hashCode => itemId.hashCode;

  @override
  String toString() {
    return 'PurchaseItem{productId: $productId, quantity: $quantity, buyPrice: $formattedBuyPrice}';
  }
}

class PurchaseWithItems {
  final Purchase purchase;
  final List<PurchaseItem> items;
  final Supplier? supplier;

  PurchaseWithItems({
    required this.purchase,
    required this.items,
    this.supplier,
  });

  int get totalItems => items.length;
  int get totalQuantity => items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get totalValue => purchase.totalAmount;

  String get supplierDisplay => supplier?.companyName ?? purchase.supplierDisplay;
  bool get hasExpiringItems => items.any((item) => item.isExpiringSoon);
  bool get hasExpiredItems => items.any((item) => item.isExpired);
}

enum PurchaseStatus {
  pending,
  received,
  cancelled,
}

extension PurchaseStatusExtension on PurchaseStatus {
  String get displayName {
    switch (this) {
      case PurchaseStatus.pending:
        return 'Pending';
      case PurchaseStatus.received:
        return 'Received';
      case PurchaseStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayColor {
    switch (this) {
      case PurchaseStatus.pending:
        return 'orange';
      case PurchaseStatus.received:
        return 'green';
      case PurchaseStatus.cancelled:
        return 'red';
    }
  }
}