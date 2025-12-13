class Product {
  final int id;
  final String barcode;
  final String name;
  final int sellPrice; // In cents
  final int stockQuantity;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.sellPrice,
    required this.stockQuantity,
  });

  factory Product.fromSql(Map<String, dynamic> row) {
    return Product(
      id: row['product_id'],
      barcode: row['barcode'],
      name: row['product_name'],
      sellPrice: row['sell_price'],
      stockQuantity: row['stock_quantity'],
    );
  }

  // Helper for UI
  double get priceDouble => sellPrice / 100.0;
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  int get total => product.sellPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}
