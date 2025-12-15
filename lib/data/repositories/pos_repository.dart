import 'package:mini_mart_pos/data/models/product.dart';
import 'package:postgres/postgres.dart';
import 'package:mini_mart_pos/data/database_service.dart';

class PosRepository {
  final DatabaseService _dbService;

  PosRepository(this._dbService);

  // Find product by barcode
  Future<Product?> getProduct(String barcode) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM products WHERE barcode = @barcode'),
      parameters: {'barcode': barcode},
    );

    if (result.isEmpty) return null;
    return Product.fromMap(result.first.toColumnMap());
  }

  // Execute Sale Transaction
  Future<void> submitSale(List<CartItem> items, int total, int userId) async {
    final conn = await _dbService.connection;

    await conn.runTx((ctx) async {
      final invoice = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Insert Header
      final saleRes = await ctx.execute(
        Sql.named('''
          INSERT INTO sales (invoice_no, user_id, sub_total, grand_total, payment_method)
          VALUES (@inv, @uid, @tot, @tot, 'CASH') RETURNING sale_id
        '''),
        parameters: {'inv': invoice, 'uid': userId, 'tot': total},
      );
      final saleId = saleRes.first[0] as int;

      // 2. Insert Items (Trigger handles stock deduction)
      for (var item in items) {
        await ctx.execute(
          Sql.named('''
            INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, total_price)
            VALUES (@sid, @pid, @qty, @price, @total)
          '''),
          parameters: {
            'sid': saleId,
            'pid': item.product.productId,
            'qty': item.quantity,
            'price': item.product.sellPrice,
            'total': item.total,
          },
        );
      }
    });
  }
}
