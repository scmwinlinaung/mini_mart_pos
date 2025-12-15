import 'package:get_it/get_it.dart';
import '../data/database_service.dart';
import '../data/repositories/pos_repository.dart';
import '../data/repositories/auth_repository.dart';

final sl = GetIt.instance;

void setupLocator() {
  // Services
  sl.registerLazySingleton<DatabaseService>(() => DatabaseService());

  // Repositories
  sl.registerLazySingleton<PosRepository>(() => PosRepository(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
}
