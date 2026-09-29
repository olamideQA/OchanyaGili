import 'package:equatable/equatable.dart';
import 'package:ochanya_gili/features/checkout/domain/models/delivery_address.dart';

enum OrderStatus {
  pendingPayment('pending_payment', 'Awaiting Payment'),
  paid('paid', 'Paid & Confirmed'),
  confirmed('confirmed', 'Confirmed'),
  processing('processing', 'Processing In Atelier'),
  inProduction('in_production', 'In Production'),
  readyForFitting('ready_for_fitting', 'Ready For Fitting'),
  readyForDelivery('ready_for_delivery', 'Ready For Delivery'),
  shipped('shipped', 'Dispatched / In Transit'),
  delivered('delivered', 'Delivered to Client'),
  cancelled('cancelled', 'Cancelled'),
  refunded('refunded', 'Refunded');

  final String dbValue;
  final String displayName;

  const OrderStatus(this.dbValue, this.displayName);

  static OrderStatus fromString(String val) {
    return OrderStatus.values.firstWhere(
      (e) => e.dbValue == val,
      orElse: () => OrderStatus.pendingPayment,
    );
  }

  bool get isActive =>
      this != OrderStatus.delivered &&
      this != OrderStatus.cancelled &&
      this != OrderStatus.refunded;

  bool get isCompleted => this == OrderStatus.delivered;

  bool get isCancelled =>
      this == OrderStatus.cancelled || this == OrderStatus.refunded;

  int get stageNumber {
    switch (this) {
      case OrderStatus.pendingPayment:
      case OrderStatus.paid:
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.processing:
        return 2;
      case OrderStatus.inProduction:
        return 3;
      case OrderStatus.readyForFitting:
      case OrderStatus.readyForDelivery:
        return 4;
      case OrderStatus.shipped:
        return 5;
      case OrderStatus.delivered:
        return 6;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return 0;
    }
  }
}

enum PaymentStatus {
  pending('pending', 'Pending'),
  processing('processing', 'Processing'),
  successful('successful', 'Successful'),
  failed('failed', 'Failed'),
  refunded('refunded', 'Refunded'),
  partiallyRefunded('partially_refunded', 'Partially Refunded');

  final String dbValue;
  final String displayName;

  const PaymentStatus(this.dbValue, this.displayName);

  static PaymentStatus fromString(String val) {
    return PaymentStatus.values.firstWhere(
      (e) => e.dbValue == val,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantLabel;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? measurementProfileId;
  final Map<String, dynamic>? customOptions;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantLabel,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.measurementProfileId,
    this.customOptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'variant_label': variantLabel,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'measurement_profile_id': measurementProfileId,
      'custom_options': customOptions,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      variantId: json['variant_id'] as String?,
      productName: json['product_name'] as String? ?? '',
      variantLabel: json['variant_label'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      measurementProfileId: json['measurement_profile_id'] as String?,
      customOptions: json['custom_options'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        variantId,
        productName,
        variantLabel,
        quantity,
        unitPrice,
        totalPrice,
        measurementProfileId,
        customOptions,
      ];
}

class OrderStatusHistoryEntry extends Equatable {
  final String id;
  final String orderId;
  final String? fromStatus;
  final String toStatus;
  final String? changedBy;
  final String? notes;
  final DateTime createdAt;

  const OrderStatusHistoryEntry({
    required this.id,
    required this.orderId,
    this.fromStatus,
    required this.toStatus,
    this.changedBy,
    this.notes,
    required this.createdAt,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String? ?? '',
      changedBy: json['changed_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, orderId, fromStatus, toStatus, changedBy, notes, createdAt];
}

class AtelierTimelineStage extends Equatable {
  final int stageNumber;
  final String title;
  final String subtitle;
  final String description;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final DateTime? completedAt;
  final String? notes;

  const AtelierTimelineStage({
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    this.completedAt,
    this.notes,
  });

  static List<AtelierTimelineStage> buildStages(
    OrderStatus currentStatus,
    List<OrderStatusHistoryEntry> history,
  ) {
    final currentStage = currentStatus.stageNumber;

    DateTime? getStageTimestamp(List<String> dbStatuses) {
      for (final h in history.reversed) {
        if (dbStatuses.contains(h.toStatus)) {
          return h.createdAt;
        }
      }
      return null;
    }

    String? getStageNotes(List<String> dbStatuses) {
      for (final h in history.reversed) {
        if (dbStatuses.contains(h.toStatus) && h.notes != null && h.notes!.isNotEmpty) {
          return h.notes;
        }
      }
      return null;
    }

    final rawStages = [
      (
        1,
        'COMMISSION RECEIVED & AUTHENTICATED',
        'Order confirmed through secure atelier gateway',
        'Garment specifications, sizing parameters, and textile allocations entered into the master ledger.',
        ['pending_payment', 'paid', 'confirmed'],
      ),
      (
        2,
        'TEXTILE SOURCING & PATTERN DRAFTING',
        'Fabrics curated & anatomical block patterns prepared',
        'Fabrics inspected for drape and grain. Bespoke anatomical pattern drafted to client measurements.',
        ['processing'],
      ),
      (
        3,
        'ATELIER CRAFTSMANSHIP & CUTTING',
        'Hand-cut and assembled by master couturiers',
        'Internal canvassing, sculptural peplum boning, and hand-finished pick stitching applied.',
        ['in_production'],
      ),
      (
        4,
        'QUALITY INSPECTION & SALON PRESSING',
        'Rigorous couture assessment & finishing',
        'Seams, hemlines, and closures verified against luxury standard before presentation packaging.',
        ['ready_for_fitting', 'ready_for_delivery'],
      ),
      (
        5,
        'DISPATCHED / EN ROUTE',
        'In transit with private courier partner',
        'Secured in protective dust carrier and dispatched with direct tracking.',
        ['shipped'],
      ),
      (
        6,
        'HAND-DELIVERED TO CLIENT',
        'Commission successfully received',
        'Garment safely presented to client. Ready for salon fitting or private gala wear.',
        ['delivered'],
      ),
    ];

    return rawStages.map((stage) {
      final num = stage.$1;
      final isComp = currentStage > num || (currentStage == 6 && num == 6);
      final isCurr = currentStage == num && currentStage != 6;
      final isPend = currentStage < num;

      return AtelierTimelineStage(
        stageNumber: num,
        title: stage.$2,
        subtitle: stage.$3,
        description: stage.$4,
        isCompleted: isComp,
        isCurrent: isCurr,
        isPending: isPend,
        completedAt: getStageTimestamp(stage.$5),
        notes: getStageNotes(stage.$5),
      );
    }).toList();
  }

  @override
  List<Object?> get props => [
        stageNumber,
        title,
        subtitle,
        description,
        isCompleted,
        isCurrent,
        isPending,
        completedAt,
        notes,
      ];
}

class AppOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String profileId;
  final String? addressId;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final PaymentStatus paymentStatus;
  final String? paymentReference;
  final String? paymentProvider;
  final String? notes;
  final String? customerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final DeliveryAddress? deliveryAddress;
  final List<OrderStatusHistoryEntry> statusHistory;

  const AppOrder({
    required this.id,
    required this.orderNumber,
    required this.profileId,
    this.addressId,
    required this.status,
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.discountAmount = 0.0,
    required this.total,
    required this.paymentStatus,
    this.paymentReference,
    this.paymentProvider,
    this.notes,
    this.customerNotes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.deliveryAddress,
    this.statusHistory = const [],
  });

  bool get isPaid => status == OrderStatus.paid || paymentStatus == PaymentStatus.successful;

  List<AtelierTimelineStage> get timelineStages =>
      AtelierTimelineStage.buildStages(status, statusHistory);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'profile_id': profileId,
      'address_id': addressId,
      'status': status.dbValue,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
      'total': total,
      'payment_status': paymentStatus.dbValue,
      'payment_reference': paymentReference,
      'payment_provider': paymentProvider,
      'notes': notes,
      'customer_notes': customerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();

    final rawHistory = json['order_status_history'] as List<dynamic>? ?? [];
    final history = rawHistory
        .map((e) => OrderStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    DeliveryAddress? addr;
    if (json['addresses'] != null && json['addresses'] is Map<String, dynamic>) {
      addr = DeliveryAddress.fromJson(json['addresses'] as Map<String, dynamic>);
    }

    return AppOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      addressId: json['address_id'] as String?,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending_payment'),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String? ?? 'pending'),
      paymentReference: json['payment_reference'] as String?,
      paymentProvider: json['payment_provider'] as String?,
      notes: json['notes'] as String?,
      customerNotes: json['customer_notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      items: items,
      deliveryAddress: addr,
      statusHistory: history,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        profileId,
        addressId,
        status,
        subtotal,
        deliveryFee,
        discountAmount,
        total,
        paymentStatus,
        paymentReference,
        paymentProvider,
        notes,
        customerNotes,
        createdAt,
        updatedAt,
        items,
        deliveryAddress,
        statusHistory,
      ];
}
