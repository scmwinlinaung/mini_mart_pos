import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mini_mart_pos/data/models/product.dart';
import 'package:mini_mart_pos/data/repositories/pos_repository.dart';

// States
abstract class ScannerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {}

class ScannerLoading extends ScannerState {}

class ScannerFailure extends ScannerState {
  final String message;
  ScannerFailure(this.message);
}

class ScannerSuccess extends ScannerState {
  final Product product;
  ScannerSuccess(this.product);
}

// Cubit
class ScannerCubit extends Cubit<ScannerState> {
  final PosRepository _repo;

  ScannerCubit(this._repo) : super(ScannerInitial());

  Future<void> scanBarcode(String barcode) async {
    if (barcode.isEmpty) return;
    emit(ScannerLoading());

    try {
      final product = await _repo.getProduct(barcode);
      if (product != null) {
        emit(ScannerSuccess(product));
        // Immediately reset to initial so we can scan the same item again if needed
        emit(ScannerInitial());
      } else {
        emit(ScannerFailure("Product not found: $barcode"));
      }
    } catch (e) {
      emit(ScannerFailure(e.toString()));
    }
  }
}
