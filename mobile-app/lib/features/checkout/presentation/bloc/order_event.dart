import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class PlaceOrderEvent extends OrderEvent {
  final List<Map<String, dynamic>> items;
  final String deliveryAddress;
  final double totalAmount;
  final String paymentMethod;
  final String shopId;
  final String customerPhone;
  final double codAmount;

  const PlaceOrderEvent({
    required this.items,
    required this.deliveryAddress,
    required this.totalAmount,
    this.paymentMethod = 'COD',
    this.shopId = '',
    this.customerPhone = '',
    this.codAmount = 0.0,
  });

  @override
  List<Object?> get props => [
        items,
        deliveryAddress,
        totalAmount,
        paymentMethod,
        shopId,
        customerPhone,
        codAmount,
      ];
}

class FetchOrderHistoryEvent extends OrderEvent {
  const FetchOrderHistoryEvent();
}

class FetchOrderTrackingEvent extends OrderEvent {
  final int orderId;

  const FetchOrderTrackingEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CancelOrderEvent extends OrderEvent {
  final int orderId;
  final String reason;

  const CancelOrderEvent({required this.orderId, required this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

class DeleteOrderEvent extends OrderEvent {
  final int orderId;

  const DeleteOrderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class LoadShopkeeperOrdersEvent extends OrderEvent {
  const LoadShopkeeperOrdersEvent();
}

class AcceptOrderEvent extends OrderEvent {
  final String orderId;
  final int prepTimeMinutes;

  const AcceptOrderEvent({required this.orderId, required this.prepTimeMinutes});

  @override
  List<Object?> get props => [orderId, prepTimeMinutes];
}

class FindRiderEvent extends OrderEvent {
  final String orderId;

  const FindRiderEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RequestAdminApprovalEvent extends OrderEvent {
  final String orderId;
  final double? codAmount;

  const RequestAdminApprovalEvent(this.orderId, {this.codAmount});

  @override
  List<Object?> get props => [orderId, codAmount];
}

class StartDeliveryTripEvent extends OrderEvent {
  final String orderId;

  const StartDeliveryTripEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CompleteDeliveryEvent extends OrderEvent {
  final String orderId;

  const CompleteDeliveryEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
