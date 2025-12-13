import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/data/logic/cart/cart_cubit.dart';
import 'package:mini_mart_pos/data/logic/scanner/scanner_cubit.dart';
import 'core/service_locator.dart';
import 'data/repositories/pos_repository.dart';
import 'presentation/screens/pos_screen.dart';

void main() {
  setupLocator(); // Init GetIt
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ScannerCubit(sl<PosRepository>())),
        BlocProvider(create: (_) => CartCubit(sl<PosRepository>())),
      ],
      child: MaterialApp(
        title: 'Postgres POS BLoC',
        theme: ThemeData(primarySwatch: Colors.indigo),
        home: const PosScreen(),
      ),
    );
  }
}
