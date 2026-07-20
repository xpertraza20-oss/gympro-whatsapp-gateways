import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../domain/entities/cart_item.dart';
import '../../../product_catalog/domain/entities/product.dart';

class CartBloc extends HydratedBloc<CartEvent, CartState> {
  CartBloc() : super(const CartState(items: [])) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ClearCartConflictEvent>(_onClearCartConflict);
    on<ClearAndAddEvent>(_onClearAndAdd);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    // Single-Shop Rule: If cart is not empty, check shopId
    if (state.items.isNotEmpty) {
      final firstItem = state.items.first;
      final existingShopId = firstItem.product.shopId;
      final newShopId = event.product.shopId;

      // If shopId is set and is different, trigger conflict state
      if (existingShopId.isNotEmpty && newShopId.isNotEmpty && existingShopId != newShopId) {
        emit(state.copyWith(
          pendingProduct: event.product,
          conflictShopName: firstItem.product.shopName.isNotEmpty
              ? firstItem.product.shopName
              : 'Previous Shop',
        ));
        return;
      }
    }

    final List<CartItem> updatedItems = List.from(state.items);
    final int index = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (index >= 0) {
      updatedItems[index] = updatedItems[index].copyWith(
        quantity: updatedItems[index].quantity + 1,
      );
    } else {
      updatedItems.add(CartItem(product: event.product, quantity: 1));
    }

    // Emit and ensure conflict is cleared
    emit(state.copyWith(items: updatedItems, clearConflict: true));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items)
      ..removeWhere((item) => item.product.id == event.productId);

    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final int index = updatedItems.indexWhere((item) => item.product.id == event.productId);

    if (index >= 0) {
      if (event.quantity <= 0) {
        updatedItems.removeAt(index);
      } else {
        updatedItems[index] = updatedItems[index].copyWith(quantity: event.quantity);
      }
      emit(state.copyWith(items: updatedItems));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
  }

  void _onClearCartConflict(ClearCartConflictEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(clearConflict: true));
  }

  void _onClearAndAdd(ClearAndAddEvent event, Emitter<CartState> emit) {
    // Clear whole cart and insert new product
    final List<CartItem> items = [CartItem(product: event.product, quantity: 1)];
    emit(CartState(
      items: items,
      pendingProduct: null,
      conflictShopName: null,
    ));
  }

  @override
  CartState? fromJson(Map<String, dynamic> json) {
    try {
      return CartState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(CartState state) {
    try {
      return state.toJson();
    } catch (_) {
      return null;
    }
  }
}

