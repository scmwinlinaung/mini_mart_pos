import 'app_strings.dart';

class AppStringsEn {
  static Map<String, String> get strings => {
    // App
    AppStrings.appName: 'Mini Mart POS',
    AppStrings.miniMartPOS: 'Mini Mart POS',

    // Dashboard
    AppStrings.dashboard: 'Dashboard',
    AppStrings.dashboardTitle: 'Dashboard Overview',
    AppStrings.todaySales: 'Today\'s Sales',
    AppStrings.totalProducts: 'Total Products',
    AppStrings.lowStockItems: 'Low Stock Items',
    AppStrings.recentTransactions: 'Recent Transactions',
    AppStrings.quickActions: 'Quick Actions',

    // Menu Items
    AppStrings.productManagement: 'Product Management',
    AppStrings.sales: 'Sales',
    AppStrings.inventory: 'Inventory',
    AppStrings.customerManagement: 'Customer Management',
    AppStrings.supplierManagement: 'Supplier Management',
    AppStrings.purchaseManagement: 'Purchase Management',
    AppStrings.expenseManagement: 'Expense Management',
    AppStrings.reports: 'Reports',
    AppStrings.settings: 'Settings',

    // Product Management
    AppStrings.productManagementTitle: 'Product Management',
    AppStrings.addProduct: 'Add Product',
    AppStrings.editProduct: 'Edit Product',
    AppStrings.productName: 'Product Name',
    AppStrings.barcode: 'Barcode',
    AppStrings.category: 'Category',
    AppStrings.price: 'Price',
    AppStrings.costPrice: 'Cost Price',
    AppStrings.sellPrice: 'Sell Price',
    AppStrings.stockQuantity: 'Stock Quantity',
    AppStrings.unit: 'Unit',
    AppStrings.supplier: 'Supplier',
    AppStrings.description: 'Description',
    AppStrings.searchProducts: 'Search Products',
    AppStrings.scanBarcode: 'Scan Barcode',

    // Sales
    AppStrings.salesTitle: 'Sales',
    AppStrings.newSale: 'New Sale',
    AppStrings.scanProduct: 'Scan Product',
    AppStrings.addToCart: 'Add to Cart',
    AppStrings.cart: 'Cart',
    AppStrings.subtotal: 'Subtotal',
    AppStrings.tax: 'Tax',
    AppStrings.discount: 'Discount',
    AppStrings.total: 'Total',
    AppStrings.paymentMethod: 'Payment Method',
    AppStrings.cash: 'Cash',
    AppStrings.card: 'Card',
    AppStrings.qrCode: 'QR Code',
    AppStrings.credit: 'Credit',
    AppStrings.completeSale: 'Complete Sale',
    AppStrings.printReceipt: 'Print Receipt',

    // Inventory
    AppStrings.inventoryTitle: 'Inventory Management',
    AppStrings.stockIn: 'Stock In',
    AppStrings.stockOut: 'Stock Out',
    AppStrings.stockAdjustment: 'Stock Adjustment',
    AppStrings.currentStock: 'Current Stock',
    AppStrings.reorderLevel: 'Reorder Level',
    AppStrings.lastUpdated: 'Last Updated',

    // Customer Management
    AppStrings.customerManagementTitle: 'Customer Management',
    AppStrings.addCustomer: 'Add Customer',
    AppStrings.editCustomer: 'Edit Customer',
    AppStrings.customerName: 'Customer Name',
    AppStrings.customerPhoneNumber: 'Phone Number',
    AppStrings.customerEmail: 'Email',
    AppStrings.address: 'Address',
    AppStrings.loyaltyPoints: 'Loyalty Points',
    AppStrings.searchCustomers: 'Search Customers',

    // Supplier Management
    AppStrings.supplierManagementTitle: 'Supplier Management',
    AppStrings.addSupplier: 'Add Supplier',
    AppStrings.editSupplier: 'Edit Supplier',
    AppStrings.companyName: 'Company Name',
    AppStrings.contactPerson: 'Contact Person',
    AppStrings.supplierPhone: 'Phone Number',
    AppStrings.supplierAddress: 'Address',
    AppStrings.searchSuppliers: 'Search Suppliers',

    // Purchase Management
    AppStrings.purchaseManagementTitle: 'Purchase Management',
    AppStrings.newPurchase: 'New Purchase',
    AppStrings.purchaseOrder: 'Purchase Order',
    AppStrings.invoiceNumber: 'Invoice Number',
    AppStrings.purchaseDate: 'Purchase Date',
    AppStrings.expectedDelivery: 'Expected Delivery',
    AppStrings.receivedItems: 'Received Items',

    // Expense Management
    AppStrings.expenseManagementTitle: 'Expense Management',
    AppStrings.addExpense: 'Add Expense',
    AppStrings.editExpense: 'Edit Expense',
    AppStrings.expenseCategory: 'Expense Category',
    AppStrings.expenseTitle: 'Expense Title',
    AppStrings.expenseDescription: 'Expense Description',
    AppStrings.expenseAmount: 'Expense Amount',
    AppStrings.expenseDate: 'Expense Date',

    // Reports
    AppStrings.reportsTitle: 'Reports',
    AppStrings.salesReport: 'Sales Report',
    AppStrings.inventoryReport: 'Inventory Report',
    AppStrings.profitLossReport: 'Profit & Loss Report',
    AppStrings.customerReport: 'Customer Report',
    AppStrings.supplierReport: 'Supplier Report',
    AppStrings.expenseReport: 'Expense Report',
    AppStrings.dateRange: 'Date Range',
    AppStrings.generateReport: 'Generate Report',
    AppStrings.exportReport: 'Export Report',

    // Common Actions
    AppStrings.save: 'Save',
    AppStrings.cancel: 'Cancel',
    AppStrings.delete: 'Delete',
    AppStrings.edit: 'Edit',
    AppStrings.add: 'Add',
    AppStrings.update: 'Update',
    AppStrings.search: 'Search',
    AppStrings.filter: 'Filter',
    AppStrings.export: 'Export',
    AppStrings.import: 'Import',
    AppStrings.print: 'Print',
    AppStrings.view: 'View',
    AppStrings.select: 'Select',
    AppStrings.confirm: 'Confirm',
    AppStrings.yes: 'Yes',
    AppStrings.no: 'No',
    AppStrings.ok: 'OK',
    AppStrings.error: 'Error',
    AppStrings.success: 'Success',
    AppStrings.warning: 'Warning',
    AppStrings.info: 'Info',

    // User Interface
    AppStrings.loading: 'Loading...',
    AppStrings.noDataFound: 'No data found',
    AppStrings.noResultsFound: 'No results found',
    AppStrings.somethingWentWrong: 'Something went wrong',
    AppStrings.tryAgain: 'Try Again',
    AppStrings.retry: 'Retry',
    AppStrings.close: 'Close',
    AppStrings.back: 'Back',
    AppStrings.next: 'Next',
    AppStrings.previous: 'Previous',
    AppStrings.finish: 'Finish',

    // Authentication
    AppStrings.login: 'Login',
    AppStrings.logout: 'Logout',
    AppStrings.username: 'Username',
    AppStrings.password: 'Password',
    AppStrings.forgotPassword: 'Forgot Password?',
    AppStrings.rememberMe: 'Remember Me',
    AppStrings.loginSuccess: 'Login successful',
    AppStrings.loginFailed: 'Login failed',
    AppStrings.invalidCredentials: 'Invalid credentials',

    // Validation Messages
    AppStrings.required: 'This field is required',
    AppStrings.invalidEmail: 'Invalid email address',
    AppStrings.invalidPhone: 'Invalid phone number',
    AppStrings.passwordTooShort: 'Password is too short',
    AppStrings.passwordsDoNotMatch: 'Passwords do not match',
    AppStrings.fieldCannotBeEmpty: 'This field cannot be empty',

    // Success Messages
    AppStrings.savedSuccessfully: 'Saved successfully',
    AppStrings.updatedSuccessfully: 'Updated successfully',
    AppStrings.deletedSuccessfully: 'Deleted successfully',
    AppStrings.operationCompleted: 'Operation completed successfully',

    // Error Messages
    AppStrings.saveFailed: 'Failed to save',
    AppStrings.updateFailed: 'Failed to update',
    AppStrings.deleteFailed: 'Failed to delete',
    AppStrings.networkError: 'Network error',
    AppStrings.serverError: 'Server error',
    AppStrings.databaseError: 'Database error',

    // Settings
    AppStrings.settingsTitle: 'Settings',
    AppStrings.language: 'Language',
    AppStrings.theme: 'Theme',
    AppStrings.darkMode: 'Dark Mode',
    AppStrings.lightMode: 'Light Mode',
    AppStrings.systemMode: 'System Mode',
    AppStrings.notifications: 'Notifications',
    AppStrings.backup: 'Backup',
    AppStrings.restore: 'Restore',
    AppStrings.about: 'About',
    AppStrings.help: 'Help',
    AppStrings.contactSupport: 'Contact Support',

    // Units
    AppStrings.pieces: 'Pieces',
    AppStrings.kilograms: 'Kilograms',
    AppStrings.grams: 'Grams',
    AppStrings.liters: 'Liters',
    AppStrings.milliliters: 'Milliliters',
    AppStrings.meters: 'Meters',
    AppStrings.centimeters: 'Centimeters',
    AppStrings.box: 'Box',
    AppStrings.pack: 'Pack',
    AppStrings.bottle: 'Bottle',
    AppStrings.can: 'Can',
    AppStrings.bag: 'Bag',

    // Categories
    AppStrings.beverages: 'Beverages',
    AppStrings.snacks: 'Snacks',
    AppStrings.homeLiving: 'Home & Living',
    AppStrings.electronics: 'Electronics',
    AppStrings.personalCare: 'Personal Care',
    AppStrings.food: 'Food',
    AppStrings.stationery: 'Stationery',

    // User Roles
    AppStrings.admin: 'Administrator',
    AppStrings.cashier: 'Cashier',
    AppStrings.manager: 'Manager',

    // Additional user management strings
    AppStrings.deactivateUser: 'Deactivate User',
    AppStrings.activateUser: 'Activate User',
    AppStrings.resetPassword: 'Reset Password',
  };
}