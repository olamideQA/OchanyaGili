import 'package:equatable/equatable.dart';

class ShippingMethod extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final double cost;
  final int estimatedDays;

  const ShippingMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.estimatedDays,
  });

  static const List<ShippingMethod> availableMethods = [
    ShippingMethod(
      id: 'standard',
      title: 'Standard Atelier Delivery',
      subtitle: '3 – 5 Business Days across Nigeria',
      cost: 4500.0,
      estimatedDays: 4,
    ),
    ShippingMethod(
      id: 'express',
      title: 'Express Priority Courier',
      subtitle: '1 – 2 Business Days Expedited Dispatch',
      cost: 9500.0,
      estimatedDays: 2,
    ),
    ShippingMethod(
      id: 'international',
      title: 'International DHL Express',
      subtitle: '5 – 7 Business Days Worldwide Insured Transit',
      cost: 45000.0,
      estimatedDays: 6,
    ),
    ShippingMethod(
      id: 'salon_pickup',
      title: 'Atelier Salon Collection (Abuja)',
      subtitle: 'Complimentary private collection at our Maitama salon',
      cost: 0.0,
      estimatedDays: 1,
    ),
  ];

  static ShippingMethod get defaultMethod => availableMethods.first;

  @override
  List<Object?> get props => [id, title, subtitle, cost, estimatedDays];
}
