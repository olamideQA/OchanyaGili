import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/cart/presentation/providers/cart_provider.dart';
import 'package:ochanya_gili/features/checkout/domain/models/delivery_address.dart';
import 'package:ochanya_gili/features/checkout/domain/models/shipping_method.dart';
import 'package:ochanya_gili/features/orders/data/orders_repository.dart';
import 'package:ochanya_gili/features/payment/data/payment_service.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Client Details Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'FCT Abuja');
  final _notesController = TextEditingController();

  ShippingMethod _selectedShipping = ShippingMethod.defaultMethod;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Prefill with authenticated user if available
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _fullNameController.text = user.name;
      _emailController.text = user.email;
      if (user.phone != null) _phoneController.text = user.phone!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = ref.read(cartNotifierProvider);
    if (cartState.isEmpty) {
      context.go('/cart');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      final profileId = user?.id ?? '00000000-0000-0000-0000-000000000000';

      final address = DeliveryAddress(
        profileId: profileId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isNotEmpty ? _addressLine2Controller.text.trim() : null,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: 'Nigeria',
      );

      // 1. Create order in Supabase with pending_payment status
      final ordersRepo = ref.read(ordersRepositoryProvider);
      final order = await ordersRepo.createOrder(
        profileId: profileId,
        items: cartState.items,
        address: address,
        shippingMethod: _selectedShipping,
        customerNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // 2. Initialize payment with Paystack provider
      final paymentProvider = ref.read(paymentProviderProvider);
      final paymentInit = await paymentProvider.initializePayment(
        orderNumber: order.orderNumber,
        amount: order.total,
        email: _emailController.text.trim(),
        customerName: _fullNameController.text.trim(),
        metadata: {
          'order_id': order.id,
          'item_count': cartState.totalCount,
        },
      );

      if (!mounted) return;

      // 3. Prompt luxury payment gateway dialog
      final colors = Theme.of(context).extension<AppColorTokens>()!;
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => _buildPaystackModal(dialogCtx, colors, order.orderNumber, order.total, paymentInit.reference),
      );

      if (verified == true) {
        // 4. Server-Side Verification:
        // Execute server RPC verify_and_mark_order_paid to strictly confirm payment
        final verification = await paymentProvider.verifyPayment(
          orderNumber: order.orderNumber,
          reference: paymentInit.reference,
          amount: order.total,
        );

        if (verification.isSuccessful) {
          // Clear cart on server confirmation
          ref.read(cartNotifierProvider.notifier).clearCart();
          ref.read(analyticsServiceProvider).trackPurchaseCompleted(
            orderNumber: order.orderNumber,
            total: order.total,
            itemCount: order.items.length,
          );
          if (mounted) {
            context.go('/checkout/confirmation/${order.orderNumber}');
          }
          return;
        } else {
          setState(() {
            _errorMessage = verification.message ?? 'Server verification failed.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Payment was declined or cancelled. Your order remains pending.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during checkout: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildPaystackModal(
    BuildContext dialogCtx,
    AppColorTokens colors,
    String orderNumber,
    double total,
    String reference,
  ) {
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: colors.primaryText,
                child: Text('PAYSTACK', style: TextStyle(color: colors.onAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              const SizedBox(width: 8),
              Text('Secured Payment Gateway', style: TextStyle(fontSize: 13, color: colors.secondaryText)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Order: $orderNumber',
            style: TextStyle(fontFamily: 'Playfair Display', fontSize: 18, color: colors.primaryText),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: colors.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Authorised:', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
                  Text(currency.format(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.primaryText)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Transaction Reference: $reference', style: TextStyle(color: colors.secondaryText, fontSize: 11)),
            const SizedBox(height: 20),
            Text(
              'Select payment channel (simulated environment for testing):',
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text('Cancel', style: TextStyle(color: colors.error)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryText,
            foregroundColor: colors.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('AUTHORIZE PAYMENT (SUCCESS)', style: TextStyle(fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final cartState = ref.watch(cartNotifierProvider);
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final subtotal = cartState.subtotal;
    final total = subtotal + _selectedShipping.cost;

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64.0 : 20.0,
          vertical: 40.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/cart'),
                        child: Text('BAG', style: TextStyle(color: colors.secondaryText, fontSize: 11, letterSpacing: 1.5)),
                      ),
                      Text('  /  ', style: TextStyle(color: colors.secondaryText, fontSize: 11)),
                      Text('ATELIER CHECKOUT', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'BESPOKE CHECKOUT',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: isDesktop ? 36 : 28,
                      letterSpacing: 2.0,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Please review client shipping details and authorize payment.', style: TextStyle(color: colors.secondaryText, fontSize: 14)),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      color: colors.error.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.error),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: colors.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildForm(colors)),
                        const SizedBox(width: 48),
                        Expanded(flex: 2, child: _buildSidebar(cartState, colors, currency, subtotal, total)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildForm(colors),
                        const SizedBox(height: 40),
                        _buildSidebar(cartState, colors, currency, subtotal, total),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Client Contact
        _buildSectionHeader('1. CLIENT CONTACT', colors),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telephone Number *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Phone number required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email Address (for order receipts & fitting updates) *'),
          validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
        ),
        const SizedBox(height: 36),

        // 2. Delivery Address
        _buildSectionHeader('2. DELIVERY ADDRESS', colors),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressLine1Controller,
          decoration: const InputDecoration(labelText: 'Street Address / Residence *'),
          validator: (val) => val == null || val.trim().isEmpty ? 'Street address required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressLine2Controller,
          decoration: const InputDecoration(labelText: 'Apartment, Suite, Estate (Optional)'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State / Region *'),
                validator: (val) => val == null || val.trim().isEmpty ? 'State required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // 3. Shipping Options
        _buildSectionHeader('3. ATELIER DISPATCH METHOD', colors),
        const SizedBox(height: 16),
        ...ShippingMethod.availableMethods.map((method) {
          final isSelected = _selectedShipping.id == method.id;
          final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

          return InkWell(
            onTap: () => setState(() => _selectedShipping = method),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(
                  color: isSelected ? colors.primaryText : colors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.primaryText : colors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primaryText,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(method.title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(method.subtitle, style: TextStyle(color: colors.secondaryText, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    method.cost == 0 ? 'FREE' : currency.format(method.cost),
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSidebar(
    dynamic cartState,
    AppColorTokens colors,
    NumberFormat currency,
    double subtotal,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ORDER SUMMARY',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 18,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          // Mini line item previews
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cartState.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = cartState.items[idx];
              final img = item.product.images.isNotEmpty ? item.product.images.first.imageUrl : '';
              return Row(
                children: [
                  Container(
                    width: 48,
                    height: 60,
                    color: colors.surfaceVariant,
                    child: img.isNotEmpty
                        ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primaryText)),
                        Text('Qty: ${item.quantity}  •  ${item.variant?.size ?? "Standard"}', style: TextStyle(fontSize: 11, color: colors.secondaryText)),
                      ],
                    ),
                  ),
                  Text(currency.format(item.lineTotal), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.primaryText)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
              Text(currency.format(subtotal), style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping (${_selectedShipping.title})', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
              Text(_selectedShipping.cost == 0 ? 'FREE' : currency.format(_selectedShipping.cost), style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL TO PAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText, letterSpacing: 1.0)),
              Text(
                currency.format(total),
                style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.bold, color: colors.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryText,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: _isProcessing ? null : _handlePayment,
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    'PAY ${currency.format(total)} WITH PAYSTACK',
                    style: const TextStyle(letterSpacing: 2.0, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: colors.secondaryText),
              const SizedBox(width: 6),
              Text('Paystack 256-Bit Bank Grade Encryption', style: TextStyle(fontSize: 11, color: colors.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold, color: colors.primaryText)),
        const SizedBox(height: 8),
        Divider(color: colors.border),
      ],
    );
  }
}
