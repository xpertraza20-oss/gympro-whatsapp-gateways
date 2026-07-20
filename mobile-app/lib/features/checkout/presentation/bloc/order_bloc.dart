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
    on<DeleteOrderEvent>(_onDeleteOrder);
    on<LoadShopkeeperOrdersEvent>(_onLoadShopkeeperOrders);
    on<AcceptOrderEvent>(_onAcceptOrder);
    on<FindRiderEvent>(_onFindRider);
    on<RequestAdminApprovalEvent>(_onRequestAdminApproval);
    on<StartDeliveryTripEvent>(_onStartDeliveryTrip);
    on<CompleteDeliveryEvent>(_onCompleteDelivery);
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

  Future<void> _onDeleteOrder(DeleteOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      await orderRepository.deleteOrder(event.orderId);
      emit(OrderDeleteSuccess(
        orderId: event.orderId,
        message: 'Order successfully removed from history.',
      ));
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.toLowerCase().contains('not found')) {
        emit(OrderDeleteSuccess(
          orderId: event.orderId,
          message: 'Order successfully removed from history.',
        ));
      } else {
        emit(OrderError(errorStr));
      }
    }
  }

  Future<void> _onLoadShopkeeperOrders(LoadShopkeeperOrdersEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      // Simulate fetching orders from repository
      final orders = await orderRepository.getOrderHistory();
      emit(ShopkeeperOrdersLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onAcceptOrder(AcceptOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      // Simulate API call to accept order with prep time
      await Future.delayed(const Duration(milliseconds: 800));
      emit(OrderAcceptedSuccess(
        orderId: event.orderId,
        prepTimeMinutes: event.prepTimeMinutes,
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onFindRider(FindRiderEvent event, Emitter<OrderState> emit) async {
    emit(FindingRiderProgress(event.orderId));
    try {
      // Simulate broadcasting to riders for 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      emit(FindingRiderSuccess(event.orderId));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onRequestAdminApproval(RequestAdminApprovalEvent event, Emitter<OrderState> emit) async {
    emit(AdminApprovalProgress(event.orderId));
    try {
      // Parse order ID (strip non-numeric prefix like "GFG-")
      final orderId = int.tryParse(event.orderId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final amount = event.codAmount ?? 0.0;

      // Submit request to backend
      await orderRepository.requestCodApproval(orderId: orderId, amount: amount);

      // Poll for admin decision (max 60s, every 4s)
      int attempts = 0;
      while (attempts < 15) {
        await Future.delayed(const Duration(seconds: 4));
        final status = await orderRepository.getCodApprovalStatus(orderId);
        final approvalStatus = status?['status']?.toString() ?? 'pending';

        if (approvalStatus == 'approved') {
          emit(AdminApprovalSuccess(event.orderId));
          return;
        } else if (approvalStatus == 'rejected') {
          emit(OrderError('Admin rejected the COD approval: ${status?['reject_reason'] ?? 'No reason provided.'}'));
          return;
        }
        attempts++;
      }

      // Timed out without response
      emit(OrderError('Admin approval timed out. Please try again or contact support.'));
    } catch (e) {
      emit(OrderError('COD approval request failed: ${e.toString()}'));
    }
  }

  Future<void> _onStartDeliveryTrip(StartDeliveryTripEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(DeliveryTripStarted(event.orderId));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCompleteDelivery(CompleteDeliveryEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      emit(DeliveryCompletedSuccess(event.orderId));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
