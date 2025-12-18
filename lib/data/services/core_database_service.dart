import 'package:postgres/postgres.dart';

// Core database service that only manages the database connection and initialization
// This is extracted from the original DatabaseService to provide separation of concerns
class CoreDatabaseService {
  Connection? _connection;

  final Endpoint _endpoint = Endpoint(
    host: '127.0.0.1',
    database: 'mini_mart_pos',
    username: 'postgres',
    password: 'password', // Update this for production
    port: 5432,
  );

  Future<Connection> get connection async {
    if (_connection != null && _connection!.isOpen) return _connection!;
    _connection = await Connection.open(
      _endpoint,
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    return _connection!;
  }

  // Initialize database with all tables
  Future<void> initializeDatabase() async {
    try {
      final conn = await connection;
      print('✅ Direct database connection successful');

      // Create all tables based on the schema
      await _createTables(conn);
      await _insertDefaultData(conn);
      await _createTriggers(conn);
      print('✅ Database initialized successfully');
      return;
    } catch (directConnectionError) {
      print('⚠️  Direct connection failed: $directConnectionError');
      rethrow;
    }
  }

  Future<void> _createTables(Connection conn) async {
    // 1. Roles table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS roles (
        role_id SERIAL PRIMARY KEY,
        role_name TEXT NOT NULL UNIQUE
      )
    ''');

    // 2. Users table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id SERIAL PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        role_id INT REFERENCES roles(role_id),
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // 3. Categories table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        category_id SERIAL PRIMARY KEY,
        category_name TEXT NOT NULL
      )
    ''');

    // 4. Suppliers table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        supplier_id SERIAL PRIMARY KEY,
        company_name TEXT NOT NULL,
        contact_name TEXT,
        phone_number TEXT,
        address TEXT
      )
    ''');

    // 5. Products table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS products (
        product_id SERIAL PRIMARY KEY,
        category_id INT REFERENCES categories(category_id),
        supplier_id INT REFERENCES suppliers(supplier_id),
        barcode TEXT UNIQUE NOT NULL,
        product_name TEXT NOT NULL,
        description TEXT,
        cost_price INT DEFAULT 0,
        sell_price INT NOT NULL,
        stock_quantity INT DEFAULT 0,
        reorder_level INT DEFAULT 10,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // 6. Customers table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        customer_id SERIAL PRIMARY KEY,
        phone_number TEXT UNIQUE,
        full_name TEXT,
        address TEXT,
        loyalty_points INT DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // 7. Sales table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        sale_id SERIAL PRIMARY KEY,
        invoice_no TEXT UNIQUE NOT NULL,
        user_id INT REFERENCES users(user_id),
        customer_id INT REFERENCES customers(customer_id),
        sub_total INT NOT NULL,
        tax_amount INT DEFAULT 0,
        discount_amount INT DEFAULT 0,
        grand_total INT NOT NULL,
        payment_method TEXT,
        payment_status TEXT DEFAULT 'PAID',
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // 8. Sale items table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        sale_item_id SERIAL PRIMARY KEY,
        sale_id INT REFERENCES sales(sale_id) ON DELETE CASCADE,
        product_id INT REFERENCES products(product_id),
        quantity INT NOT NULL,
        unit_price INT NOT NULL,
        total_price INT NOT NULL
      )
    ''');

    // 9. Stock movements table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        movement_id SERIAL PRIMARY KEY,
        product_id INT REFERENCES products(product_id),
        user_id INT REFERENCES users(user_id),
        movement_type TEXT CHECK (movement_type IN ('SALE', 'PURCHASE', 'RETURN', 'ADJUSTMENT')),
        quantity INT NOT NULL,
        notes TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // 10. Purchases table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        purchase_id SERIAL PRIMARY KEY,
        supplier_id INT REFERENCES suppliers(supplier_id),
        user_id INT REFERENCES users(user_id),
        supplier_invoice_no TEXT,
        total_amount INT DEFAULT 0,
        status TEXT DEFAULT 'RECEIVED',
        purchase_date TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // 11. Purchase items table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        item_id SERIAL PRIMARY KEY,
        purchase_id INT REFERENCES purchases(purchase_id),
        product_id INT REFERENCES products(product_id),
        quantity INT NOT NULL,
        buy_price INT NOT NULL,
        expiry_date DATE
      )
    ''');

    // 12. Expense categories table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        category_id SERIAL PRIMARY KEY,
        category_name TEXT NOT NULL
      )
    ''');

    // 13. Expenses table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        expense_id SERIAL PRIMARY KEY,
        category_id INT REFERENCES expense_categories(category_id),
        user_id INT REFERENCES users(user_id),
        title TEXT NOT NULL,
        description TEXT,
        amount INT NOT NULL,
        expense_date DATE DEFAULT CURRENT_DATE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    // Create indexes for performance
    await conn.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)',
    );
    await conn.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_invoice_no ON sales(invoice_no)',
    );
    await conn.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)',
    );
    await conn.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)',
    );
  }

  Future<void> _insertDefaultData(Connection conn) async {
    // Check if data already exists
    final roleCount = await conn
        .execute('SELECT COUNT(*) FROM roles')
        .then((result) => result.first.first as int);

    if (roleCount > 0) return; // Data already exists

    // Insert default roles
    await conn.execute(
      Sql.named('INSERT INTO roles (role_name) VALUES (@name)'),
      parameters: {'name': 'Admin'},
    );
    await conn.execute(
      Sql.named('INSERT INTO roles (role_name) VALUES (@name)'),
      parameters: {'name': 'Cashier'},
    );
    await conn.execute(
      Sql.named('INSERT INTO roles (role_name) VALUES (@name)'),
      parameters: {'name': 'Manager'},
    );

    // Insert default admin user (password: admin123)
    await conn.execute(
      Sql.named('''
      INSERT INTO users (username, password_hash, full_name, role_id, is_active)
      VALUES (@username, @password, @full_name, @role_id, @is_active)
    '''),
      parameters: {
        'username': 'admin',
        'password': 'hashed_admin_password',
        'full_name': 'System Administrator',
        'role_id': 1,
        'is_active': true,
      },
    );

    // Insert default cashier user (password: cashier123)
    await conn.execute(
      Sql.named('''
      INSERT INTO users (username, password_hash, full_name, role_id, is_active)
      VALUES (@username, @password, @full_name, @role_id, @is_active)
    '''),
      parameters: {
        'username': 'cashier',
        'password': 'hashed_cashier_password',
        'full_name': 'Default Cashier',
        'role_id': 2,
        'is_active': true,
      },
    );

    // Insert default categories
    await conn.execute(
      Sql.named('INSERT INTO categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Beverages'},
    );
    await conn.execute(
      Sql.named('INSERT INTO categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Snacks'},
    );
    await conn.execute(
      Sql.named('INSERT INTO categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Home & Living'},
    );
    await conn.execute(
      Sql.named('INSERT INTO categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Personal Care'},
    );
    await conn.execute(
      Sql.named('INSERT INTO categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Electronics'},
    );

    // Insert sample products
    final sampleProducts = [
      {
        'barcode': '1234567890123',
        'product_name': 'Coca Cola 500ml',
        'description': 'Refreshing cola drink',
        'category_id': 1,
        'cost_price': 150, // $1.50
        'sell_price': 200, // $2.00
        'stock_quantity': 50,
        'reorder_level': 10,
      },
      {
        'barcode': '1234567890124',
        'product_name': 'Lay\'s Potato Chips',
        'description': 'Classic potato chips',
        'category_id': 2,
        'cost_price': 100, // $1.00
        'sell_price': 150, // $1.50
        'stock_quantity': 30,
        'reorder_level': 8,
      },
      {
        'barcode': '1234567890125',
        'product_name': 'Bottled Water 1L',
        'description': 'Pure drinking water',
        'category_id': 1,
        'cost_price': 50, // $0.50
        'sell_price': 100, // $1.00
        'stock_quantity': 100,
        'reorder_level': 20,
      },
    ];

    for (var product in sampleProducts) {
      await conn.execute(
        Sql.named('''
        INSERT INTO products (barcode, product_name, description, category_id, cost_price, sell_price, stock_quantity, reorder_level)
        VALUES (@barcode, @product_name, @description, @category_id, @cost_price, @sell_price, @stock_quantity, @reorder_level)
      '''),
        parameters: product,
      );
    }

    // Insert default expense categories
    await conn.execute(
      Sql.named('INSERT INTO expense_categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Rent'},
    );
    await conn.execute(
      Sql.named('INSERT INTO expense_categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Utilities'},
    );
    await conn.execute(
      Sql.named('INSERT INTO expense_categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Salary'},
    );
    await conn.execute(
      Sql.named('INSERT INTO expense_categories (category_name) VALUES (@name)'),
      parameters: {'name': 'Supplies'},
    );
  }

  Future<void> _createTriggers(Connection conn) async {
    // Trigger for automatic stock deduction on sale
    await conn.execute('''
      CREATE OR REPLACE FUNCTION fn_process_sale_stock()
      RETURNS TRIGGER AS \$\$
      BEGIN
        -- Deduct from Product Inventory
        UPDATE products
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE product_id = NEW.product_id;

        -- Add entry to Stock Ledger
        INSERT INTO stock_movements (product_id, movement_type, quantity, notes, created_at)
        VALUES (NEW.product_id, 'SALE', -NEW.quantity, 'Auto-deduct Sale ID: ' || NEW.sale_id, NOW());

        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;
    ''');

    await conn.execute('''
      DROP TRIGGER IF EXISTS trg_sale_stock ON sale_items;
      CREATE TRIGGER trg_sale_stock
      AFTER INSERT ON sale_items
      FOR EACH ROW
      EXECUTE FUNCTION fn_process_sale_stock();
    ''');

    // Trigger for automatic stock addition on purchase
    await conn.execute('''
      CREATE OR REPLACE FUNCTION fn_process_purchase_stock()
      RETURNS TRIGGER AS \$\$
      BEGIN
        -- Add to Product Inventory
        UPDATE products
        SET stock_quantity = stock_quantity + NEW.quantity,
            cost_price = NEW.buy_price
        WHERE product_id = NEW.product_id;

        -- Add entry to Stock Ledger
        INSERT INTO stock_movements (product_id, movement_type, quantity, notes, created_at)
        VALUES (NEW.product_id, 'PURCHASE', NEW.quantity, 'Stock In Purchase ID: ' || NEW.purchase_id, NOW());

        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;
    ''');

    await conn.execute('''
      DROP TRIGGER IF EXISTS trg_purchase_stock ON purchase_items;
      CREATE TRIGGER trg_purchase_stock
      AFTER INSERT ON purchase_items
      FOR EACH ROW
      EXECUTE FUNCTION fn_process_purchase_stock();
    ''');
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(dynamic txn) action) async {
    final conn = await connection;
    return await conn.runTx((txn) async {
      return await action(txn);
    });
  }

  // Close connection
  Future<void> close() async {
    if (_connection != null && _connection!.isOpen) {
      await _connection!.close();
      _connection = null;
    }
  }
}