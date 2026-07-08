import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'COD';

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _placeOrder(CartState cartState) {
    if (_formKey.currentState!.validate()) {
      final List<Map<String, dynamic>> itemsPayload = cartState.items.map((item) {
        return {
          'product_id': item.product.id,
          'title': item.product.title,
          'price': item.product.price,
          'quantity': item.quantity,
        };
      }).toList();

      context.read<OrderBloc>().add(PlaceOrderEvent(
            items: itemsPayload,
            deliveryAddress: _addressController.text.trim(),
            totalAmount: cartState.subtotal,
            paymentMethod: _paymentMethod,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderPlacedSuccess) {
            // Clear cart completely
            context.read<CartBloc>().add(const ClearCartEvent());
            // Navigate to success page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderSuccessScreen(order: state.order),
              ),
            );
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error placing order: ${state.message}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, orderState) {
          final isLoading = orderState is OrderLoading;

          return BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              if (cartState.items.isEmpty && orderState is! OrderPlacedSuccess) {
                return const Center(child: Text('Your cart is empty.'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Header
                      const Text(
                        'Delivery Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          hintText: 'Enter your full street address, building/apartment, city',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a delivery address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Contact Phone Number',
                          hintText: 'e.g., +923001234567',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a contact phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Payment Method Header
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 12),

                      // COD Option Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                        ),
                        child: RadioListTile<String>(
                          value: 'COD',
                          groupValue: _paymentMethod,
                          activeColor: const Color(0xFF10B981),
                          title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Pay with cash when your package is delivered'),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _paymentMethod = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Order Summary Invoice Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Items (${cartState.totalItemCount})', style: const TextStyle(color: Colors.grey)),
                                Text('\$${cartState.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Delivery Fee', style: TextStyle(color: Colors.grey)),
                                Text('Free', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(
                                  '\$${cartState.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Submit/Place Order Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _placeOrder(cartState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
