import 'package:equatable/equatable.dart';

/// Summary of an order for admin overview widgets
class AdminOrderSummary extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final double total;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;

  const AdminOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] as String? ?? 'Private Client';
    return AdminOrderSummary(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      customerName: fullName,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, orderNumber, customerName, total, status, paymentStatus, createdAt];
}

/// Summary of a custom request for admin overview widgets
class AdminRequestSummary extends Equatable {
  final String id;
  final String requestNumber;
  final String customerName;
  final String garmentType;
  final String status;
  final DateTime createdAt;

  const AdminRequestSummary({
    required this.id,
    required this.requestNumber,
    required this.customerName,
    required this.garmentType,
    required this.status,
    required this.createdAt,
  });

  factory AdminRequestSummary.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] as String? ?? 'Private Client';
    return AdminRequestSummary(
      id: json['id'] as String? ?? '',
      requestNumber: json['request_number'] as String? ?? '',
      customerName: fullName,
      garmentType: json['garment_type'] as String? ?? 'Bespoke',
      status: json['status'] as String? ?? 'submitted',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, requestNumber, customerName, garmentType, status, createdAt];
}

/// Summary of an appointment for admin overview widgets
class AdminAppointmentSummary extends Equatable {
  final String id;
  final String customerName;
  final String appointmentType;
  final DateTime date;
  final String startTime;
  final String status;

  const AdminAppointmentSummary({
    required this.id,
    required this.customerName,
    required this.appointmentType,
    required this.date,
    required this.startTime,
    required this.status,
  });

  factory AdminAppointmentSummary.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] as String? ?? 'Private Client';
    final typeInfo = json['appointment_types'] as Map<String, dynamic>?;
    final typeName = typeInfo?['name'] as String? ?? 'Fitting / Consultation';
    return AdminAppointmentSummary(
      id: json['id'] as String? ?? '',
      customerName: fullName,
      appointmentType: typeName,
      date: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : (json['appointment_date'] != null
              ? DateTime.parse(json['appointment_date'] as String)
              : DateTime.now()),
      startTime: json['start_time'] as String? ?? '10:00',
      status: json['status'] as String? ?? 'confirmed',
    );
  }

  @override
  List<Object?> get props => [id, customerName, appointmentType, date, startTime, status];
}

/// Master metrics aggregated for the /admin overview screen
class AdminDashboardMetrics extends Equatable {
  final int todayOrders;
  final double todayRevenue;
  final int todayAppointments;
  final int todayCustomRequests;

  // Pipeline funnel counts
  final int pipelineRequests;
  final int pipelineQuoted;
  final int pipelineProduction;
  final int pipelineFitting;
  final int pipelineReady;

  final List<AdminOrderSummary> recentOrders;
  final List<AdminRequestSummary> recentRequests;
  final List<AdminAppointmentSummary> upcomingAppointments;

  const AdminDashboardMetrics({
    required this.todayOrders,
    required this.todayRevenue,
    required this.todayAppointments,
    required this.todayCustomRequests,
    required this.pipelineRequests,
    required this.pipelineQuoted,
    required this.pipelineProduction,
    required this.pipelineFitting,
    required this.pipelineReady,
    required this.recentOrders,
    required this.recentRequests,
    required this.upcomingAppointments,
  });

  factory AdminDashboardMetrics.empty() {
    return const AdminDashboardMetrics(
      todayOrders: 0,
      todayRevenue: 0.0,
      todayAppointments: 0,
      todayCustomRequests: 0,
      pipelineRequests: 0,
      pipelineQuoted: 0,
      pipelineProduction: 0,
      pipelineFitting: 0,
      pipelineReady: 0,
      recentOrders: [],
      recentRequests: [],
      upcomingAppointments: [],
    );
  }

  @override
  List<Object?> get props => [
        todayOrders,
        todayRevenue,
        todayAppointments,
        todayCustomRequests,
        pipelineRequests,
        pipelineQuoted,
        pipelineProduction,
        pipelineFitting,
        pipelineReady,
        recentOrders,
        recentRequests,
        upcomingAppointments,
      ];
}

/// Customer directory item
class AdminCustomer extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final DateTime createdAt;
  final int ordersCount;
  final int measurementsCount;

  const AdminCustomer({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.createdAt,
    this.ordersCount = 0,
    this.measurementsCount = 0,
  });

  factory AdminCustomer.fromJson(Map<String, dynamic> json) {
    return AdminCustomer(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'customer',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      measurementsCount: (json['measurements_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, phone, role, createdAt, ordersCount, measurementsCount];
}

/// Raw materials & inventory item
class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String? description;
  final double quantity;
  final String unit;
  final double costPerUnit;
  final String? supplier;
  final double reorderThreshold;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
    this.supplier,
    required this.reorderThreshold,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity > 0 && quantity <= reorderThreshold;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      costPerUnit: (json['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      supplier: json['supplier'] as String?,
      reorderThreshold: (json['reorder_threshold'] as num?)?.toDouble() ?? 5.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'cost_per_unit': costPerUnit,
      'supplier': supplier,
      'reorder_threshold': reorderThreshold,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        description,
        quantity,
        unit,
        costPerUnit,
        supplier,
        reorderThreshold,
        isActive,
      ];
}

/// Audit payment record in admin view
class AdminPaymentRecord extends Equatable {
  final String id;
  final String? orderId;
  final String profileId;
  final String? customerName;
  final String? customerEmail;
  final double amount;
  final String currency;
  final String provider;
  final String? providerReference;
  final String? providerStatus;
  final String status;
  final String paymentType;
  final Map<String, dynamic>? metadata;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const AdminPaymentRecord({
    required this.id,
    this.orderId,
    required this.profileId,
    this.customerName,
    this.customerEmail,
    required this.amount,
    required this.currency,
    required this.provider,
    this.providerReference,
    this.providerStatus,
    required this.status,
    required this.paymentType,
    this.metadata,
    this.verifiedAt,
    required this.createdAt,
  });

  factory AdminPaymentRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return AdminPaymentRecord(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String?,
      profileId: json['profile_id'] as String? ?? '',
      customerName: profile?['full_name'] as String?,
      customerEmail: profile?['email'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'NGN',
      provider: json['provider'] as String? ?? 'paystack',
      providerReference: json['provider_reference'] as String?,
      providerStatus: json['provider_status'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentType: json['payment_type'] as String? ?? 'order_full',
      metadata: json['metadata'] as Map<String, dynamic>?,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'].toString()) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        profileId,
        customerName,
        customerEmail,
        amount,
        currency,
        provider,
        providerReference,
        providerStatus,
        status,
        paymentType,
        verifiedAt,
        createdAt,
      ];
}

/// Discount code / voucher model
class AdminDiscount extends Equatable {
  final String id;
  final String code;
  final String? description;
  final String type; // 'percentage' | 'fixed_amount'
  final double value;
  final double? minOrderAmount;
  final int? maxUses;
  final int usedCount;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  const AdminDiscount({
    required this.id,
    required this.code,
    this.description,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxUses,
    this.usedCount = 0,
    this.startsAt,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory AdminDiscount.fromJson(Map<String, dynamic> json) {
    return AdminDiscount(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
      maxUses: (json['max_uses'] as num?)?.toInt(),
      usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at'].toString()) : null,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code.toUpperCase().trim(),
      'description': description,
      'type': type,
      'value': value,
      'min_order_amount': minOrderAmount,
      'max_uses': maxUses,
      'used_count': usedCount,
      'starts_at': startsAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        description,
        type,
        value,
        minOrderAmount,
        maxUses,
        usedCount,
        startsAt,
        expiresAt,
        isActive,
        createdAt,
      ];
}

/// Private internal note by designer or admin
/// MUST NEVER BE RETURNED OR ACCESSIBLE TO CUSTOMER
class DesignerNote extends Equatable {
  final String id;
  final String entityType; // 'customer' | 'order' | 'custom_request' | 'appointment'
  final String entityId;
  final String content;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;

  const DesignerNote({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.content,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory DesignerNote.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return DesignerNote(
      id: json['id'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? 'customer',
      entityId: json['entity_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      createdByName: profile?['full_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, entityType, entityId, content, createdBy, createdByName, createdAt];
}

/// Media storage asset
class AdminMediaItem extends Equatable {
  final String name;
  final String bucket;
  final String url;
  final DateTime? createdAt;
  final int? size;

  const AdminMediaItem({
    required this.name,
    required this.bucket,
    required this.url,
    this.createdAt,
    this.size,
  });

  @override
  List<Object?> get props => [name, bucket, url, createdAt, size];
}
