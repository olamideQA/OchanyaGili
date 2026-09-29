import 'package:equatable/equatable.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

class CartItem extends Equatable {
  final String id;
  final Product product;
  final ProductVariant? variant;
  final String? measurementProfileId;
  final String? measurementProfileName;
  final int quantity;
  final double unitPrice;

  const CartItem({
    required this.id,
    required this.product,
    this.variant,
    this.measurementProfileId,
    this.measurementProfileName,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  static String generateId({
    required String productId,
    String? variantId,
    String? measurementProfileId,
  }) {
    return '${productId}_${variantId ?? "default"}_${measurementProfileId ?? "std"}';
  }

  CartItem copyWith({
    String? id,
    Product? product,
    ProductVariant? variant,
    String? measurementProfileId,
    String? measurementProfileName,
    int? quantity,
    double? unitPrice,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      variant: variant ?? this.variant,
      measurementProfileId: measurementProfileId ?? this.measurementProfileId,
      measurementProfileName: measurementProfileName ?? this.measurementProfileName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'variant': variant?.toJson(),
      'measurement_profile_id': measurementProfileId,
      'measurement_profile_name': measurementProfileName,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      variant: json['variant'] != null
          ? ProductVariant.fromJson(json['variant'] as Map<String, dynamic>)
          : null,
      measurementProfileId: json['measurement_profile_id'] as String?,
      measurementProfileName: json['measurement_profile_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        product,
        variant,
        measurementProfileId,
        measurementProfileName,
        quantity,
        unitPrice,
      ];
}

class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  int get totalCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  bool get hasMadeToOrderItems =>
      items.any((item) => item.product.productType.isMadeToOrder);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
