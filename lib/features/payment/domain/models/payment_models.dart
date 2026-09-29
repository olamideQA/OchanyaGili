import 'package:equatable/equatable.dart';

class PaymentInitResult extends Equatable {
  final String reference;
  final String orderNumber;
  final double amount;
  final String? authorizationUrl;
  final String? accessCode;

  const PaymentInitResult({
    required this.reference,
    required this.orderNumber,
    required this.amount,
    this.authorizationUrl,
    this.accessCode,
  });

  @override
  List<Object?> get props => [reference, orderNumber, amount, authorizationUrl, accessCode];
}

class PaymentVerificationResult extends Equatable {
  final bool isSuccessful;
  final String reference;
  final String orderNumber;
  final double amount;
  final String? channel;
  final String? message;
  final DateTime? paidAt;
  final String? orderId;

  const PaymentVerificationResult({
    required this.isSuccessful,
    required this.reference,
    required this.orderNumber,
    required this.amount,
    this.channel,
    this.message,
    this.paidAt,
    this.orderId,
  });

  @override
  List<Object?> get props => [
        isSuccessful,
        reference,
        orderNumber,
        amount,
        channel,
        message,
        paidAt,
        orderId,
      ];
}
