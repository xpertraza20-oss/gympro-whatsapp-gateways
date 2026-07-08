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

  const PlaceOrderEvent({
    required this.items,
    required this.deliveryAddress,
    required this.totalAmount,
    this.paymentMethod = 'COD',
  });

  @override
  List<Object?> get props => [items, deliveryAddress, totalAmount, paymentMethod];
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
