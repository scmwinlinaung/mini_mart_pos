part of 'dashboard_cubit.dart';

abstract class DashboardState {
  const DashboardState();

  const factory DashboardState.initial() = Initial;
  const factory DashboardState.loading() = Loading;
  const factory DashboardState.loaded(DashboardData dashboardData) = Loaded;
  const factory DashboardState.error(String message) = Error;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(DashboardData dashboardData) loaded,
    required T Function(String message) error,
  }) {
    if (this is Initial) {
      return initial();
    } else if (this is Loading) {
      return loading();
    } else if (this is Loaded) {
      return loaded((this as Loaded).dashboardData);
    } else if (this is Error) {
      return error((this as Error).message);
    } else {
      throw StateError('Invalid DashboardState: $this');
    }
  }
}

class Initial extends DashboardState {
  const Initial();
}

class Loading extends DashboardState {
  const Loading();
}

class Loaded extends DashboardState {
  final DashboardData dashboardData;
  const Loaded(this.dashboardData);
}

class Error extends DashboardState {
  final String message;
  const Error(this.message);
}