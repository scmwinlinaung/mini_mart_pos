import 'package:get_it/get_it.dart';
import 'services/database_service.dart';
import '../data/repositories/pos_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/supplier_repository.dart';
import '../data/repositories/purchase_repository.dart';
import '../data/logic/dashboard/dashboard_cubit.dart';
import '../data/logic/product/product_cubit.dart';
import '../data/logic/user/user_cubit.dart';
import '../data/logic/category/category_cubit.dart';
import '../data/logic/supplier/supplier_cubit.dart';
import '../data/logic/purchase/purchase_cubit.dart';
import 'bloc/language/language_bloc.dart';

final sl = GetIt.instance;

void setupLocator() {
  // Services
  sl.registerLazySingleton<DatabaseService>(() => DatabaseService());

  // Repositories
  sl.registerLazySingleton<PosRepository>(() => PosRepository(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
  sl.registerLazySingleton<ProductRepository>(() => ProductRepository(sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepository(sl()));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepository(sl()));
  sl.registerLazySingleton<SupplierRepository>(() => SupplierRepository(sl()));
  sl.registerLazySingleton<PurchaseRepository>(() => PurchaseRepository(sl()));

  // BLoCs/Cubits
  sl.registerFactory<DashboardCubit>(() => DashboardCubit(sl()));
  sl.registerFactory<ProductCubit>(() => ProductCubit());
  sl.registerFactory<UserCubit>(() => UserCubit());
  sl.registerFactory<CategoryCubit>(() => CategoryCubit());
  sl.registerFactory<SupplierCubit>(() => SupplierCubit());
  sl.registerFactory<PurchaseCubit>(() => PurchaseCubit());
  sl.registerLazySingleton<LanguageBloc>(() => LanguageBloc());
}
