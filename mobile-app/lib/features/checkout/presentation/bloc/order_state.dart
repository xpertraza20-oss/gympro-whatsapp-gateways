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

class OrderDeleteSuccess extends OrderState {
  final int orderId;
  final String message;

  const OrderDeleteSuccess({required this.orderId, required this.message});

  @override
  List<Object?> get props => [orderId, message];
}

class ShopkeeperOrdersLoaded extends OrderState {
  final List<dynamic> orders;

  const ShopkeeperOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderAcceptedSuccess extends OrderState {
  final String orderId;
  final int prepTimeMinutes;

  const OrderAcceptedSuccess({required this.orderId, required this.prepTimeMinutes});

  @override
  List<Object?> get props => [orderId, prepTimeMinutes];
}

class FindingRiderProgress extends OrderState {
  final String orderId;

  const FindingRiderProgress(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class FindingRiderSuccess extends OrderState {
  final String orderId;

  const FindingRiderSuccess(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class AdminApprovalProgress extends OrderState {
  final String orderId;

  const AdminApprovalProgress(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class AdminApprovalSuccess extends OrderState {
  final String orderId;

  const AdminApprovalSuccess(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class DeliveryTripStarted extends OrderState {
  final String orderId;

  const DeliveryTripStarted(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class DeliveryCompletedSuccess extends OrderState {
  final String orderId;

  const DeliveryCompletedSuccess(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
