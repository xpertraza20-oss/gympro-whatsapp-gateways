import 'package:equatable/equatable.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderPlacedSuccess extends OrderState {
  final Map<String, dynamic> order;

  const OrderPlacedSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderHistoryLoaded extends OrderState {
  final List<dynamic> orders;

  const OrderHistoryLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderTrackingLoaded extends OrderState {
  final Map<String, dynamic> order;

  const OrderTrackingLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderCancelSuccess extends OrderState {
  final int orderId;
  final String message;

  const OrderCancelSuccess({required this.orderId, required this.message});

  @override
  List<Object?> get props => [orderId, message];
}
