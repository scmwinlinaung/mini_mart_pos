// Central models export file - imports all model classes
export 'sales.dart';
export 'purchases.dart';
export 'expenses.dart';
export 'auth.dart';

class Product {
  final int productId;
  final String barcode;
  final String productName;
  final String? description;
  final int categoryId;
  final String? categoryName;
  final int supplierId;
  final String? supplierName;
  final int unitTypeId;
  final String? unitCode;
  final String? unitName;
  final int costPrice; // In cents
  final int sellPrice; // In cents
  final int stockQuantity;
  final int reorderLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.productId,
    required this.barcode,
    required this.productName,
    this.description,
    required this.categoryId,
    this.categoryName,
    required this.supplierId,
    this.supplierName,
    required this.unitTypeId,
    this.unitCode,
    this.unitName,
    required this.costPrice,
    required this.sellPrice,
    required this.stockQuantity,
    this.reorderLevel = 10,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['product_id'] as int,
      barcode: map['barcode'] as String,
      productName: map['product_name'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int? ?? 0,
      categoryName: map['category_name'] as String?,
      supplierId: map['supplier_id'] as int? ?? 0,
      supplierName: map['supplier_name'] as String?,
      unitTypeId: map['unit_type_id'] as int? ?? 1,
      unitCode: map['unit_code'] as String?,
      unitName: map['unit_name'] as String?,
      costPrice: map['cost_price'] as int? ?? 0,
      sellPrice: map['sell_price'] as int,
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      reorderLevel: map['reorder_level'] as int? ?? 10,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] is DateTime
          ? map['updated_at'] as DateTime
          : DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'barcode': barcode,
      'product_name': productName,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'unit_type_id': unitTypeId,
      'unit_code': unitCode,
      'unit_name': unitName,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'stock_quantity': stockQuantity,
      'reorder_level': reorderLevel,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? productId,
    String? barcode,
    String? productName,
    String? description,
    int? categoryId,
    String? categoryName,
    int? supplierId,
    String? supplierName,
    int? unitTypeId,
    String? unitCode,
    String? unitName,
    int? costPrice,
    int? sellPrice,
    int? stockQuantity,
    int? reorderLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      unitTypeId: unitTypeId ?? this.unitTypeId,
      unitCode: unitCode ?? this.unitCode,
      unitName: unitName ?? this.unitName,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for UI
  double get profitMargin =>
      sellPrice > 0 ? ((sellPrice - costPrice) / sellPrice) * 100 : 0;
  bool get isLowStock => stockQuantity <= reorderLevel;
  bool get isOutOfStock => stockQuantity <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          barcode == other.barcode;

  @override
  int get hashCode => productId.hashCode ^ barcode.hashCode;

  @override
  String toString() {
    return 'Product{productId: $productId, barcode: $barcode, productName: $productName, sellPrice: $sellPrice, stock: $stockQuantity}';
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final int unitPrice; // Price at time of adding to cart (in cents)

  CartItem({required this.product, required this.quantity, int? unitPrice})
    : unitPrice = unitPrice ?? product.sellPrice;

  int get total => unitPrice * quantity;
  String get formattedTotal => '\$$total';
  String get formattedUnitPrice => '\$$unitPrice ';

  CartItem copyWith({Product? product, int? quantity, int? unitPrice}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;

  @override
  String toString() {
    return 'CartItem{product: ${product.productName}, quantity: $quantity, total: $formattedTotal}';
  }
}

class Category {
  final int categoryId;
  final String categoryName;
  final String? description;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.description,
  });

  Category.id({required int id, required this.categoryName, this.description})
    : categoryId = id;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
    };
  }

  // Getter for compatibility with existing code
  int get id => categoryId;

  // Getter for compatibility with existing code
  String get name => categoryName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          categoryName == other.categoryName;

  @override
  int get hashCode => categoryId.hashCode ^ categoryName.hashCode;

  @override
  String toString() {
    return 'Category{categoryId: $categoryId, categoryName: $categoryName}';
  }
}

class Supplier {
  final int supplierId;
  final String companyName;
  final String? contactName;
  final String? phoneNumber;
  final String? email;
  final String? address;

  Supplier({
    required this.supplierId,
    required this.companyName,
    this.contactName,
    this.phoneNumber,
    this.email,
    this.address,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      supplierId: map['supplier_id'] as int,
      companyName: map['company_name'] as String,
      contactName: map['contact_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplier_id': supplierId,
      'company_name': companyName,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
    };
  }

  // Getter for compatibility with existing code
  int get id => supplierId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier &&
          runtimeType == other.runtimeType &&
          supplierId == other.supplierId &&
          companyName == other.companyName;

  @override
  int get hashCode => supplierId.hashCode ^ companyName.hashCode;

  @override
  String toString() {
    return 'Supplier{supplierId: $supplierId, companyName: $companyName}';
  }
}

class UnitType {
  final int unitId;
  final String unitCode;
  final String unitName;
  final bool isWeighted;
  final DateTime createdAt;

  UnitType({
    required this.unitId,
    required this.unitCode,
    required this.unitName,
    this.isWeighted = false,
    required this.createdAt,
  });

  factory UnitType.fromMap(Map<String, dynamic> map) {
    return UnitType(
      unitId: map['unit_id'] as int,
      unitCode: map['unit_code'] as String,
      unitName: map['unit_name'] as String,
      isWeighted: map['is_weighted'] as bool? ?? false,
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unit_id': unitId,
      'unit_code': unitCode,
      'unit_name': unitName,
      'is_weighted': isWeighted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitType &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          unitCode == other.unitCode;

  @override
  int get hashCode => unitId.hashCode ^ unitCode.hashCode;

  @override
  String toString() {
    return 'UnitType{unitId: $unitId, unitCode: $unitCode, unitName: $unitName}';
  }
}
