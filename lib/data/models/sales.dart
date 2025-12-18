// Sales-related models based on database schema

class Customer {
  final int customerId;
  final String? phoneNumber;
  final String? fullName;
  final String? address;
  final int loyaltyPoints;
  final DateTime createdAt;

  Customer({
    required this.customerId,
    this.phoneNumber,
    this.fullName,
    this.address,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customer_id'] as int,
      phoneNumber: map['phone_number'] as String?,
      fullName: map['full_name'] as String?,
      address: map['address'] as String?,
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          customerId == other.customerId;

  @override
  int get hashCode => customerId.hashCode;

  @override
  String toString() {
    return 'Customer{customerId: $customerId, fullName: $fullName, phoneNumber: $phoneNumber}';
  }
}

class Sale {
  final int saleId;
  final String invoiceNo;
  final int userId;
  final String? userName;
  final int? customerId;
  final String? customerName;
  final int subTotal; // in cents
  final int taxAmount; // in cents
  final int discountAmount; // in cents
  final int grandTotal; // in cents
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;

  Sale({
    required this.saleId,
    required this.invoiceNo,
    required this.userId,
    this.userName,
    this.customerId,
    this.customerName,
    required this.subTotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    required this.grandTotal,
    this.paymentMethod,
    this.paymentStatus = 'PAID',
    required this.createdAt,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      saleId: map['sale_id'] as int,
      invoiceNo: map['invoice_no'] as String,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      subTotal: map['sub_total'] as int,
      taxAmount: map['tax_amount'] as int? ?? 0,
      discountAmount: map['discount_amount'] as int? ?? 0,
      grandTotal: map['grand_total'] as int,
      paymentMethod: map['payment_method'] as String?,
      paymentStatus: map['payment_status'] as String? ?? 'PAID',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sale_id': saleId,
      'invoice_no': invoiceNo,
      'user_id': userId,
      'user_name': userName,
      'customer_id': customerId,
      'customer_name': customerName,
      'sub_total': subTotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  double get subTotalDouble => subTotal / 100.0;
  double get taxAmountDouble => taxAmount / 100.0;
  double get discountAmountDouble => discountAmount / 100.0;
  double get grandTotalDouble => grandTotal / 100.0;

  String get formattedSubTotal => '\$${(subTotal / 100).toStringAsFixed(2)}';
  String get formattedTaxAmount => '\$${(taxAmount / 100).toStringAsFixed(2)}';
  String get formattedDiscountAmount => '\$${(discountAmount / 100).toStringAsFixed(2)}';
  String get formattedGrandTotal => '\$${(grandTotal / 100).toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sale &&
          runtimeType == other.runtimeType &&
          saleId == other.saleId;

  @override
  int get hashCode => saleId.hashCode;

  @override
  String toString() {
    return 'Sale{saleId: $saleId, invoiceNo: $invoiceNo, grandTotal: $formattedGrandTotal}';
  }
}

class SaleItem {
  final int saleItemId;
  final int saleId;
  final int productId;
  final String? productName;
  final String? barcode;
  final int quantity;
  final int unitPrice; // Price at time of sale (in cents)
  final int totalPrice; // quantity * unitPrice (in cents)

  SaleItem({
    required this.saleItemId,
    required this.saleId,
    required this.productId,
    this.productName,
    this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      saleItemId: map['sale_item_id'] as int,
      saleId: map['sale_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      barcode: map['barcode'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as int,
      totalPrice: map['total_price'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sale_item_id': saleItemId,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'barcode': barcode,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  // Helper getters for UI
  double get unitPriceDouble => unitPrice / 100.0;
  double get totalPriceDouble => totalPrice / 100.0;

  String get formattedUnitPrice => '\$${(unitPrice / 100).toStringAsFixed(2)}';
  String get formattedTotalPrice => '\$${(totalPrice / 100).toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItem &&
          runtimeType == other.runtimeType &&
          saleItemId == other.saleItemId;

  @override
  int get hashCode => saleItemId.hashCode;

  @override
  String toString() {
    return 'SaleItem{productId: $productId, productName: $productName, quantity: $quantity, total: $formattedTotalPrice}';
  }
}

class StockMovement {
  final int movementId;
  final int productId;
  final String? productName;
  final int userId;
  final String? userName;
  final StockMovementType movementType;
  final int quantity; // Positive for adding stock, Negative for removing
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    required this.movementId,
    required this.productId,
    this.productName,
    required this.userId,
    this.userName,
    required this.movementType,
    required this.quantity,
    this.notes,
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      movementId: map['movement_id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String?,
      movementType: _parseMovementType(map['movement_type'] as String),
      quantity: map['quantity'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static StockMovementType _parseMovementType(String type) {
    switch (type.toUpperCase()) {
      case 'SALE':
        return StockMovementType.sale;
      case 'PURCHASE':
        return StockMovementType.purchase;
      case 'RETURN':
        return StockMovementType.return_;
      case 'ADJUSTMENT':
        return StockMovementType.adjustment;
      default:
        return StockMovementType.adjustment;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'movement_id': movementId,
      'product_id': productId,
      'product_name': productName,
      'user_id': userId,
      'user_name': userName,
      'movement_type': movementType.name.toUpperCase(),
      'quantity': quantity,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  bool get isStockOut => quantity < 0;
  bool get isStockIn => quantity > 0;
  String get formattedQuantity => '${isStockOut ? '-' : '+'}${quantity.abs()}';
  String get movementTypeDisplay {
    switch (movementType) {
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.purchase:
        return 'Purchase';
      case StockMovementType.return_:
        return 'Return';
      case StockMovementType.adjustment:
        return 'Adjustment';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          runtimeType == other.runtimeType &&
          movementId == other.movementId;

  @override
  int get hashCode => movementId.hashCode;

  @override
  String toString() {
    return 'StockMovement{productId: $productId, type: $movementTypeDisplay, quantity: $formattedQuantity}';
  }
}

enum StockMovementType {
  sale,
  purchase,
  return_,
  adjustment,
}

extension StockMovementTypeExtension on StockMovementType {
  String get displayName {
    switch (this) {
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.purchase:
        return 'Purchase';
      case StockMovementType.return_:
        return 'Return';
      case StockMovementType.adjustment:
        return 'Adjustment';
    }
  }
}

class SaleWithItems {
  final Sale sale;
  final List<SaleItem> items;
  final Customer? customer;

  SaleWithItems({
    required this.sale,
    required this.items,
    this.customer,
  });

  double get totalQuantity => items.fold<double>(0, (sum, item) => sum + item.quantity);

  int get totalItems => items.length;

  String get customerDisplay => customer?.fullName ?? 'Walk-in Customer';

  String get paymentMethodDisplay => sale.paymentMethod ?? 'Not Specified';
}