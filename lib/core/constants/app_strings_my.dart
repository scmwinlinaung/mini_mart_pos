import 'app_strings.dart';

class AppStringsMy {
  static Map<String, String> get strings => {
    // App
    AppStrings.appName: 'မီနီမတ် မတ်ထ် POS',
    AppStrings.miniMartPOS: 'မီနီမတ် မတ်ထ် POS',

    // Dashboard
    AppStrings.dashboard: 'ဒက်ရှ်ဘုတ်',
    AppStrings.dashboardTitle: 'ဒက်ရှ်ဘုတ်အကျဉ်းချုပ်',
    AppStrings.todaySales: 'ယနေ့ရောင်းအား',
    AppStrings.totalProducts: 'စုစုပေါင်းကုန်ပစ္စည်းများ',
    AppStrings.lowStockItems: 'စတော့နည်းသောပစ္စည်းများ',
    AppStrings.recentTransactions: 'နောက်ဆုံးအရောင်းအဝယ်များ',
    AppStrings.quickActions: 'လျင်မြန်သောလုပ်ငန်းများ',

    // Menu Items
    AppStrings.productManagement: 'ကုန်ပစ္စည်းစီမံခန့်ခွဲမှု',
    AppStrings.sales: 'ရောင်းအား',
    AppStrings.inventory: 'စတော့စီမံခန့်ခွဲမှု',
    AppStrings.customerManagement: 'ဖောက်သည်စီမံခန့်ခွဲမှု',
    AppStrings.supplierManagement: 'ကုန်ကူးသူစီမံခန့်ခွဲမှု',
    AppStrings.purchaseManagement: 'ဝယ်ယူမှုစီမံခန့်ခွဲမှု',
    AppStrings.expenseManagement: 'အသုံးစရိတ်စီမံခန့်ခွဲမှု',
    AppStrings.reports: 'အစီရင်ခံစာများ',
    AppStrings.settings: 'ဆက်တင်များ',

    // Product Management
    AppStrings.productManagementTitle: 'ကုန်ပစ္စည်းစီမံခန့်ခွဲမှု',
    AppStrings.addProduct: 'ကုန်ပစ္စည်းထည့်ရန်',
    AppStrings.editProduct: 'ကုန်ပစ္စည်းပြင်ဆင်ရန်',
    AppStrings.productName: 'ကုန်ပစ္စည်းအမည်',
    AppStrings.barcode: 'ဘားကုတ်',
    AppStrings.category: 'အမျိုးအစား',
    AppStrings.price: 'စျေးနှုန်း',
    AppStrings.costPrice: 'အရင်းဈေး',
    AppStrings.sellPrice: 'ရောင်းဈေး',
    AppStrings.stockQuantity: 'စတော့အရေအတွက်',
    AppStrings.unit: 'ယူနစ်',
    AppStrings.supplier: 'ကုန်ကူးသူ',
    AppStrings.description: 'ဖော်ပြချက်',
    AppStrings.searchProducts: 'ကုန်ပစ္စည်းများရှာရန်',
    AppStrings.scanBarcode: 'ဘားကုတ်စကင်ရန်',

    // Sales
    AppStrings.salesTitle: 'ရောင်းအား',
    AppStrings.newSale: 'အသစ်ရောင်းရန်',
    AppStrings.scanProduct: 'ကုန်ပစ္စည်းစကင်ရန်',
    AppStrings.addToCart: 'ခြင်းတောင်းထဲထည့်ရန်',
    AppStrings.cart: 'ခြင်းတောင်း',
    AppStrings.subtotal: 'စုစုပေါင်း',
    AppStrings.tax: 'အခွန်',
    AppStrings.discount: 'လျှော့ဈေး',
    AppStrings.total: 'စုစုပေါင်းငွေ',
    AppStrings.paymentMethod: 'ငွေချေနည်းလမ်း',
    AppStrings.cash: 'ငွေသား',
    AppStrings.card: 'ကတ်',
    AppStrings.qrCode: 'QR ကုတ်',
    AppStrings.credit: 'အရစ်ကျ',
    AppStrings.completeSale: 'ရောင်းပြီးမြောက်ရန်',
    AppStrings.printReceipt: 'ပြေစာထုတ်ရန်',

    // Inventory
    AppStrings.inventoryTitle: 'စတော့စီမံခန့်ခွဲမှု',
    AppStrings.stockIn: 'စတော့ဝင်ရောက်',
    AppStrings.stockOut: 'စတော့ထွက်ခွာ',
    AppStrings.stockAdjustment: 'စတော့ချိန်ညှိ',
    AppStrings.currentStock: 'လက်ရှိစတော့',
    AppStrings.reorderLevel: 'ပြန်မှာယူရမည့်အဆင့်',
    AppStrings.lastUpdated: 'နောက်ဆုံးအပ်ဒိတ်လုပ်ချိန်',

    // Customer Management
    AppStrings.customerManagementTitle: 'ဖောက်သည်စီမံခန့်ခွဲမှု',
    AppStrings.addCustomer: 'ဖောက်သည်ထည့်ရန်',
    AppStrings.editCustomer: 'ဖောက်သည်ပြင်ဆင်ရန်',
    AppStrings.customerName: 'ဖောက်သည်အမည်',
    AppStrings.customerPhoneNumber: 'ဖုန်းနံပါတ်',
    AppStrings.customerEmail: 'အီးမေးလ်',
    AppStrings.address: 'လိပ်စာ',
    AppStrings.loyaltyPoints: 'သစ္စာရှိအမှတ်များ',
    AppStrings.searchCustomers: 'ဖောက်သည်များရှာရန်',

    // Supplier Management
    AppStrings.supplierManagementTitle: 'ကုန်ကူးသူစီမံခန့်ခွဲမှု',
    AppStrings.addSupplier: 'ကုန်ကူးသူထည့်ရန်',
    AppStrings.editSupplier: 'ကုန်ကူးသူပြင်ဆင်ရန်',
    AppStrings.companyName: 'ကုမ္ပဏီအမည်',
    AppStrings.contactPerson: 'ဆက်သွယ်ရမည့်သူ',
    AppStrings.supplierPhone: 'ဖုန်းနံပါတ်',
    AppStrings.supplierAddress: 'လိပ်စာ',
    AppStrings.searchSuppliers: 'ကုန်ကူးသူများရှာရန်',

    // Purchase Management
    AppStrings.purchaseManagementTitle: 'ဝယ်ယူမှုစီမံခန့်ခွဲမှု',
    AppStrings.newPurchase: 'အသစ်ဝယ်ယူရန်',
    AppStrings.purchaseOrder: 'ဝယ်ယူမှုအမှာစာ',
    AppStrings.invoiceNumber: 'ငွေတောင်းစာအမှတ်',
    AppStrings.purchaseDate: 'ဝယ်ယူသည့်ရက်စွဲ',
    AppStrings.expectedDelivery: 'မျှော်လင့်ထားသောပို့ဆောင်ရက်',
    AppStrings.receivedItems: 'လက်ခံရရှိသောပစ္စည်းများ',

    // Expense Management
    AppStrings.expenseManagementTitle: 'အသုံးစရိတ်စီမံခန့်ခွဲမှု',
    AppStrings.addExpense: 'အသုံးစရိတ်ထည့်ရန်',
    AppStrings.editExpense: 'အသုံးစရိတ်ပြင်ဆင်ရန်',
    AppStrings.expenseCategory: 'အသုံးစရိတ်အမျိုးအစား',
    AppStrings.expenseTitle: 'အသုံးစရိတ်ခေါင်းစဉ်',
    AppStrings.expenseDescription: 'အသုံးစရိတ်ဖော်ပြချက်',
    AppStrings.expenseAmount: 'အသုံးစရိတ်ပမာဏ',
    AppStrings.expenseDate: 'အသုံးစရိတ်ရက်စွဲ',

    // Reports
    AppStrings.reportsTitle: 'အစီရင်ခံစာများ',
    AppStrings.salesReport: 'ရောင်းအားအစီရင်ခံစာ',
    AppStrings.inventoryReport: 'စတော့အစီရင်ခံစာ',
    AppStrings.profitLossReport: 'အမြတ်အရှုံးအစီရင်ခံစာ',
    AppStrings.customerReport: 'ဖောက်သည်အစီရင်ခံစာ',
    AppStrings.supplierReport: 'ကုန်ကူးသူအစီရင်ခံစာ',
    AppStrings.expenseReport: 'အသုံးစရိတ်အစီရင်ခံစာ',
    AppStrings.dateRange: 'ရက်စွဲအပိုင်းအခြား',
    AppStrings.generateReport: 'အစီရင်ခံစာထုတ်ရန်',
    AppStrings.exportReport: 'အစီရင်ခံစာတင်ပို့ရန်',

    // Common Actions
    AppStrings.save: 'သိမ်းဆည်းရန်',
    AppStrings.cancel: 'ပယ်ဖျက်ရန်',
    AppStrings.delete: 'ဖျက်ရန်',
    AppStrings.edit: 'ပြင်ဆင်ရန်',
    AppStrings.add: 'ထည့်ရန်',
    AppStrings.update: 'အပ်ဒိတ်လုပ်ရန်',
    AppStrings.search: 'ရှာရန်',
    AppStrings.filter: 'စိစစ်ရန်',
    AppStrings.export: 'တင်ပို့ရန်',
    AppStrings.import: 'တင်သွင်းရန်',
    AppStrings.print: 'ပုံနှိပ်ရန်',
    AppStrings.view: 'ကြည့်ရန်',
    AppStrings.select: 'ရွေးရန်',
    AppStrings.confirm: 'အတည်ပြုရန်',
    AppStrings.yes: 'ဟုတ်ကဲ့',
    AppStrings.no: 'မဟုတ်ဘူး',
    AppStrings.ok: 'OK',
    AppStrings.error: 'အမှား',
    AppStrings.success: 'အောင်မြင်ပါသည်',
    AppStrings.warning: 'သတိပေးချက်',
    AppStrings.info: 'အချက်အလက်',

    // User Interface
    AppStrings.loading: 'ဖွင့်နေသည်...',
    AppStrings.noDataFound: 'ဒေတာမရှိပါ',
    AppStrings.noResultsFound: 'ရလဒ်များမရှိပါ',
    AppStrings.somethingWentWrong: 'တစ်စုံတစ်ခုမှားယွင်းနေပါသည်',
    AppStrings.tryAgain: 'ပြန်လည်ကြိုးစားပါ',
    AppStrings.retry: 'ပြန်လည်ကြိုးစားရန်',
    AppStrings.close: 'ပိတ်ရန်',
    AppStrings.back: 'နောက်သို့',
    AppStrings.next: 'ရှေ့သို့',
    AppStrings.previous: 'အရင်က',
    AppStrings.finish: 'ပြီးဆုံးပါပြီ',

    // Authentication
    AppStrings.login: 'ဝင်ရောက်ရန်',
    AppStrings.logout: 'ထွက်ရန်',
    AppStrings.username: 'အသုံးပြုသူအမည်',
    AppStrings.password: 'စကားဝှက်',
    AppStrings.forgotPassword: 'စကားဝှက်မေ့နေလား?',
    AppStrings.rememberMe: 'ကျွန်ုပ်ကိုမှတ်ထားပါ',
    AppStrings.loginSuccess: 'အောင်စွာဝင်ရောက်ပါသည်',
    AppStrings.loginFailed: 'ဝင်ရောက်မှုမအောင်မြင်ပါ',
    AppStrings.invalidCredentials: 'မမှန်ကန်သောအသုံးပြုသူအချက်အလက်များ',

    // Validation Messages
    AppStrings.required: 'ဤနေရာသည်လိုအပ်ပါသည်',
    AppStrings.invalidEmail: 'မမှန်ကန်သောအီးမေးလ်',
    AppStrings.invalidPhone: 'မမှန်ကန်သောဖုန်းနံပါတ်',
    AppStrings.passwordTooShort: 'စကားဝှက်သည်အလွန်တိုသည်',
    AppStrings.passwordsDoNotMatch: 'စကားဝှက်များမကိုက်ညီပါ',
    AppStrings.fieldCannotBeEmpty: 'ဤနေရာကိုဗလာထား၍မရပါ',

    // Success Messages
    AppStrings.savedSuccessfully: 'အောင်စွာသိမ်းဆည်းပြီးပါပြီ',
    AppStrings.updatedSuccessfully: 'အောင်စွာအပ်ဒိတ်လုပ်ပြီးပါပြီ',
    AppStrings.deletedSuccessfully: 'အောင်စွာဖျက်ပြီးပါပြီ',
    AppStrings.operationCompleted: 'လုပ်ဆောင်ချက်အောင်စွာပြီးမြောက်ပါသည်',

    // Error Messages
    AppStrings.saveFailed: 'သိမ်းဆည်းမှုမအောင်မြင်ပါ',
    AppStrings.updateFailed: 'အပ်ဒိတ်လုပ်မှုမအောင်မြင်ပါ',
    AppStrings.deleteFailed: 'ဖျက်မှုမအောင်မြင်ပါ',
    AppStrings.networkError: 'ကွန်ယက်အမှား',
    AppStrings.serverError: 'ဆာဗာအမှား',
    AppStrings.databaseError: 'ဒေတာဘေ့စ်အမှား',

    // Settings
    AppStrings.settingsTitle: 'ဆက်တင်များ',
    AppStrings.language: 'ဘာသာစကား',
    AppStrings.theme: 'အပြင်အဆင်',
    AppStrings.darkMode: 'အမှောင်ခြစ်',
    AppStrings.lightMode: 'အလင်းခြစ်',
    AppStrings.systemMode: 'စနစ်ခြစ်',
    AppStrings.notifications: 'အကြောင်းကြားချက်များ',
    AppStrings.backup: 'အရန်းအန်း',
    AppStrings.restore: 'ပြန်လည်ထားရှိရန်',
    AppStrings.about: 'အကြောင်း',
    AppStrings.help: 'အကူအညီ',
    AppStrings.contactSupport: 'အထောက်အပံ့ဆက်သွယ်ရန်',

    // Units
    AppStrings.pieces: 'အရေအတွက်',
    AppStrings.kilograms: 'ကီလိုဂရမ်',
    AppStrings.grams: 'ဂရမ်',
    AppStrings.liters: 'လီတာ',
    AppStrings.milliliters: 'မီလီလီတာ',
    AppStrings.meters: 'မီတာ',
    AppStrings.centimeters: 'စင်တီမီတာ',
    AppStrings.box: 'ဘူး',
    AppStrings.pack: 'အထုပ်',
    AppStrings.bottle: 'ဘူးကြီး',
    AppStrings.can: 'အမှုန့်',
    AppStrings.bag: 'အိတ်',

    // Categories
    AppStrings.beverages: 'အချိုရည်များ',
    AppStrings.snacks: 'စားသောက်ကုန်ပစ္စည်းများ',
    AppStrings.homeLiving: 'အိမ်သုံးပစ္စည်းများ',
    AppStrings.electronics: 'လျှပ်စစ်ပစ္စည်းများ',
    AppStrings.personalCare: 'ကိုယ်ရေးကိုယ်တာသုံးပစ္စည်းများ',
    AppStrings.food: 'ထမင်းအသုပ်များ',
    AppStrings.stationery: 'စာရေးကိရိယာပစ္စည်းများ',

    // User Roles
    AppStrings.admin: 'စီမံခန့်ခွဲသူ',
    AppStrings.cashier: 'ငွေရှင်းစက်ဝန်ထမ်း',
    AppStrings.manager: 'စီမံကွက်',

    // Additional user management strings
    AppStrings.deactivateUser: 'အသုံးပြုသူရပ်ဆိုင်းရန်',
    AppStrings.activateUser: 'အသုံးပြုသူပြန်လည်ဖွင့်ရန်',
    AppStrings.resetPassword: 'စကားဝှက်ပြန်သတ်မှတ်ရန်',
  };
}