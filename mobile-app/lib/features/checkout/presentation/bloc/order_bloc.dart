import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository orderRepository;

  OrderBloc({required this.orderRepository}) : super(OrderInitial()) {
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<FetchOrderHistoryEvent>(_onFetchOrderHistory);
    on<FetchOrderTrackingEvent>(_onFetchOrderTracking);
    on<CancelOrderEvent>(_onCancelOrder);
  }

  Future<void> _onPlaceOrder(PlaceOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final order = await orderRepository.placeOrder(
        items: event.items,
        deliveryAddress: event.deliveryAddress,
        totalAmount: event.totalAmount,
        paymentMethod: event.paymentMethod,
      );
      emit(OrderPlacedSuccess(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onFetchOrderHistory(FetchOrderHistoryEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await orderRepository.getOrderHistory();
      emit(OrderHistoryLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onFetchOrderTracking(FetchOrderTrackingEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final order = await orderRepository.getOrderById(event.orderId);
      emit(OrderTrackingLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(CancelOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final res = await orderRepository.cancelOrder(event.orderId, event.reason);
      emit(OrderCancelSuccess(
        orderId: event.orderId,
        message: res['message'] ?? 'Order cancelled successfully.',
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
