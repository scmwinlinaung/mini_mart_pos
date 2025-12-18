import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/core/bloc/language/language_event.dart';
import 'package:mini_mart_pos/core/bloc/language/language_state.dart';
import 'package:mini_mart_pos/data/logic/category/category_cubit.dart';
import 'package:mini_mart_pos/data/logic/purchase/purchase_cubit.dart';
import 'package:mini_mart_pos/data/logic/supplier/supplier_cubit.dart';
import 'data/logic/auth/auth_cubit.dart';
import 'data/logic/cart/cart_cubit.dart';
import 'data/logic/product/product_cubit.dart';
import 'data/logic/scanner/scanner_cubit.dart';
import 'data/repositories/pos_repository.dart';
import 'core/services/database_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'core/service_locator.dart';
import 'core/bloc/language/language_bloc.dart';
import 'core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database with Docker integration
  print('🚀 Starting Mini Mart POS with Docker database integration...');

  // Don't initialize database here - let it be done lazily when needed
  // This prevents the app from crashing if Docker/database is not available

  // Setup dependency injection
  setupLocator();

  runApp(const MiniMartPOSApp());
}

class MiniMartPOSApp extends StatelessWidget {
  const MiniMartPOSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Language BLoC should be available globally - use the singleton instance
        BlocProvider.value(value: sl<LanguageBloc>()..add(LoadLanguage())),
        BlocProvider(create: (_) => PurchaseCubit()),
        // Auth cubit should be available globally
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => SupplierCubit()),
        BlocProvider(create: (_) => CategoryCubit()),
        // POS BLoCs should be available globally
        BlocProvider(create: (_) => ScannerCubit(sl<PosRepository>())),
        BlocProvider(create: (_) => CartCubit(sl<PosRepository>())),
        BlocProvider(create: (_) => ProductCubit()),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return MaterialApp(
            title: languageState.getString(AppStrings.appName),
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.indigo,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
              cardTheme: const CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            home: const AuthWrapper(),
            builder: (context, child) {
              return MediaQuery(
                // Set default text scale factor for desktop
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: Directionality(
                  textDirection: languageState.getTextDirection(),
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _dbInitializing = true;

  @override
  void initState() {
    super.initState();

    // Initialize database first, then auth state
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      print('🔧 Initializing database with Docker...');
      await DatabaseService().initializeDatabase();
      print('✅ Database initialization complete');
    } catch (e) {
      print('⚠️ Database initialization failed: $e');
      // Continue without database - show login but features may not work
    }

    setState(() {
      _dbInitializing = false;
    });

    // Initialize auth state after database initialization
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthCubit>().initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show database initialization screen
    if (_dbInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('🐳 Initializing Database...'),
              SizedBox(height: 8),
              Text(
                'Starting PostgreSQL with Docker...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState.isAuthenticated && authState.session != null) {
          return DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
