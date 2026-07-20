import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  bool _isLoadingDetails = true;

  static const _primaryColor = Color(0xFF006E2F);
  static const _primaryLight = Color(0xFF00A651);

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    const storage = FlutterSecureStorage();
    try {
      final phone = await storage.read(key: 'user_phone') ?? await storage.read(key: 'temp_phone');
      final location = await storage.read(key: 'user_location') ?? await storage.read(key: 'temp_location');
      
      if (mounted) {
        setState(() {
          _phoneController.text = phone ?? '03001234567';
          _addressController.text = location ?? 'Block D, Model Town, Lahore';
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _phoneController.text = '03001234567';
          _addressController.text = 'Block D, Model Town, Lahore';
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _placeOrder(CartState cartState) {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify a delivery address'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> itemsPayload = cartState.items.map((item) {
      return {
        'product_id': item.product.id,
        'title': item.product.title,
        'price': item.product.price,
        'quantity': item.quantity,
        'image_url': item.product.imageUrl,
        'unit': item.product.unit,
        'shop_id': item.product.shopId,
      };
    }).toList();

    final firstItem = cartState.items.first;
    final shopId = firstItem.product.shopId;
    final grandTotal = cartState.subtotal + 100.0; // Subtotal + 100 delivery fee

    context.read<OrderBloc>().add(PlaceOrderEvent(
          items: itemsPayload,
          deliveryAddress: _addressController.text.trim(),
          totalAmount: grandTotal,
          paymentMethod: _paymentMethod,
          shopId: shopId,
          customerPhone: _phoneController.text.trim(),
          codAmount: _paymentMethod == 'COD' ? grandTotal : 0.0,
        ));
  }

  void _showEditAddressDialog() {
    final tempController = TextEditingController(text: _addressController.text);
    final tempPhoneController = TextEditingController(text: _phoneController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Delivery Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _addressController.text = tempController.text;
                _phoneController.text = tempPhoneController.text;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderPlacedSuccess) {
            context.read<CartBloc>().add(const ClearCartEvent());
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
              if (cartState.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_basket_outlined, size: 44, color: _primaryColor),
                      ),
                      const SizedBox(height: 16),
                      const Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                );
              }

              final subtotal = cartState.subtotal;
              const deliveryFee = 100.0;
              final grandTotal = subtotal + deliveryFee;

              return Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. DELIVERY LOCATION CARD
                        _isLoadingDetails
                            ? const LinearProgressIndicator(color: _primaryColor)
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.location_on_rounded, color: _primaryColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Delivery Address',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9CA3AF),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _addressController.text,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Contact: ${_phoneController.text}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showEditAddressDialog,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: _primaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const SizedBox(height: 20),

                        // 2. ORDER ITEMS LIST
                        const Text(
                          'Your Items',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartState.items.length,
                          itemBuilder: (context, idx) {
                            final item = cartState.items[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF3F4F6)),
                              ),
                              child: Row(
                                children: [
                                  // Product Image placeholder
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(item.product.imageUrl, style: const TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Rs. ${item.product.price} / ${item.product.unit}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Price + Stepper
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${item.product.price * item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primaryColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              context.read<CartBloc>().add(UpdateQuantityEvent(item.product.id, item.quantity - 1));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.remove, size: 12, color: Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.quantity.toString(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              context.read<CartBloc>().add(UpdateQuantityEvent(item.product.id, item.quantity + 1));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: _primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 3. PAYMENT METHOD SECTION
                        const Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _primaryColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: _primaryColor.withOpacity(0.04), blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payments_rounded, color: _primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cash on Delivery (COD)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Pay cash when your order reaches your door',
                                      style: TextStyle(fontSize: 11, color: Colors.black38),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: _primaryColor, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. BILL SUMMARY CARD
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bill Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  Text('Rs. ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  Text('Rs. ${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const Divider(height: 20, color: Color(0xFFE5E7EB)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Grand Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                                  Text(
                                    'Rs. ${grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. STICKY BOTTOM BUTTON SECTION
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _placeOrder(cartState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Place Order • Rs. ${grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: Card(
                          margin: EdgeInsets.all(32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: _primaryColor),
                                SizedBox(height: 20),
                                Text(
                                  'Placing your order...',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

