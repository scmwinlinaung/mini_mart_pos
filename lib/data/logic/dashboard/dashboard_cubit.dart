import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_mart_pos/data/models/dashboard.dart';
import 'package:mini_mart_pos/data/repositories/pos_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final PosRepository _posRepository;

  DashboardCubit(this._posRepository) : super(const DashboardState.initial());

  Future<void> loadDashboardData() async {
    emit(const DashboardState.loading());
    try {
      final dashboardData = await _posRepository.getDashboardData();
      emit(DashboardState.loaded(dashboardData));
    } catch (e) {
      emit(DashboardState.error(e.toString()));
    }
  }

  void refresh() {
    loadDashboardData();
  }
}