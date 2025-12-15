import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/logic/auth/auth_cubit.dart';
import 'data/logic/cart/cart_cubit.dart';
import 'data/logic/scanner/scanner_cubit.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/pos_repository.dart';
import 'data/database_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'core/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService().initializeDatabase();

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
        // Auth cubit should be available globally
        BlocProvider(create: (_) => AuthCubit()),
      ],
      child: MaterialApp(
        title: 'Mini Mart POS System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: const AuthWrapper(),
        builder: (context, child) {
          return MediaQuery(
            // Set default text scale factor for desktop
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
            ),
            child: child!,
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
  @override
  void initState() {
    super.initState();
    // Initialize auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (authState.isAuthenticated && authState.session != null) {
          return MultiBlocProvider(
            providers: [
              // Provide POS-specific BLoCs only when authenticated
              BlocProvider(
                create: (_) => ScannerCubit(sl<PosRepository>()),
              ),
              BlocProvider(
                create: (_) => CartCubit(sl<PosRepository>()),
              ),
            ],
            child: DashboardScreen(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
