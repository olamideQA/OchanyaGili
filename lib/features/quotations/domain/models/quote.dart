import 'package:equatable/equatable.dart';

enum QuoteStatus {
  draft('Draft'),
  sent('Sent to Client'),
  accepted('Accepted'),
  rejected('Changes Requested'),
  revised('Revised'),
  expired('Expired');

  final String displayName;
  const QuoteStatus(this.displayName);

  static QuoteStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sent':
        return QuoteStatus.sent;
      case 'accepted':
        return QuoteStatus.accepted;
      case 'rejected':
        return QuoteStatus.rejected;
      case 'revised':
        return QuoteStatus.revised;
      case 'expired':
        return QuoteStatus.expired;
      case 'draft':
      default:
        return QuoteStatus.draft;
    }
  }

  String toJson() {
    switch (this) {
      case QuoteStatus.sent:
        return 'sent';
      case QuoteStatus.accepted:
        return 'accepted';
      case QuoteStatus.rejected:
        return 'rejected';
      case QuoteStatus.revised:
        return 'revised';
      case QuoteStatus.expired:
        return 'expired';
      case QuoteStatus.draft:
        return 'draft';
    }
  }
}

class QuoteItem extends Equatable {
  final String id;
  final String quoteId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int sortOrder;

  const QuoteItem({
    required this.id,
    required this.quoteId,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.sortOrder = 0,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'] as String? ?? '',
      quoteId: json['quote_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'quote_id': quoteId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'sort_order': sortOrder,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  @override
  List<Object?> get props => [id, quoteId, description, quantity, unitPrice, totalPrice, sortOrder];
}

class Quote extends Equatable {
  final String id;
  final String customRequestId;
  final int version;
  final double subtotal;
  final double total;
  final double depositPercentage;
  final double depositAmount;
  final double balanceAmount;
  final QuoteStatus status;
  final DateTime? validUntil;
  final String? notes;
  final String? createdBy;
  final List<QuoteItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Quote({
    required this.id,
    required this.customRequestId,
    this.version = 1,
    required this.subtotal,
    required this.total,
    this.depositPercentage = 50.0,
    required this.depositAmount,
    required this.balanceAmount,
    this.status = QuoteStatus.draft,
    this.validUntil,
    this.notes,
    this.createdBy,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isAccepted => status == QuoteStatus.accepted;
  bool get canBeAccepted => status == QuoteStatus.sent;

  factory Quote.fromJson(Map<String, dynamic> json) {
    final rawItems = json['quote_items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>)).toList();

    return Quote(
      id: json['id'] as String? ?? '',
      customRequestId: json['custom_request_id'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      depositPercentage: (json['deposit_percentage'] as num?)?.toDouble() ?? 50.0,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      status: QuoteStatus.fromString(json['status'] as String? ?? 'draft'),
      validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until'] as String) : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      items: items,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'custom_request_id': customRequestId,
      'version': version,
      'subtotal': subtotal,
      'total': total,
      'deposit_percentage': depositPercentage,
      'deposit_amount': depositAmount,
      'balance_amount': balanceAmount,
      'status': status.toJson(),
      'valid_until': validUntil?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        customRequestId,
        version,
        subtotal,
        total,
        depositPercentage,
        depositAmount,
        balanceAmount,
        status,
        validUntil,
        notes,
        createdBy,
        items,
      ];
}
