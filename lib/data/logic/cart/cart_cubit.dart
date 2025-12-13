import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mini_mart_pos/data/models/product.dart';
import 'package:mini_mart_pos/data/repositories/pos_repository.dart';

// States
enum CartStatus { initial, processing, success, failure }

class CartState extends Equatable {
  final List<CartItem> items;
  final CartStatus status;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.status = CartStatus.initial,
    this.errorMessage,
  });

  int get grandTotal => items.fold(0, (sum, item) => sum + item.total);

  CartState copyWith({
    List<CartItem>? items,
    CartStatus? status,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, status, errorMessage];
}

// Cubit
class CartCubit extends Cubit<CartState> {
  final PosRepository _repo;

  CartCubit(this._repo) : super(const CartState());

  void addProduct(Product product) {
    final List<CartItem> currentItems = List.from(state.items);

    // Check if exists
    final index = currentItems.indexWhere((i) => i.product.id == product.id);

    if (index >= 0) {
      final existing = currentItems[index];
      currentItems[index] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      currentItems.add(CartItem(product: product, quantity: 1));
    }

    emit(state.copyWith(items: currentItems, status: CartStatus.initial));
  }

  Future<void> checkout() async {
    if (state.items.isEmpty) return;

    emit(state.copyWith(status: CartStatus.processing));

    try {
      // Hardcoded User ID 1 (Admin)
      await _repo.submitSale(state.items, state.grandTotal, 1);
      emit(
        const CartState(items: [], status: CartStatus.success),
      ); // Clear cart
    } catch (e) {
      emit(
        state.copyWith(status: CartStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
