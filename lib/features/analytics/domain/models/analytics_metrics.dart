import 'package:equatable/equatable.dart';

class PopularItemMetric extends Equatable {
  final String id;
  final String name;
  final int views;
  final int purchases;
  final double revenue;

  const PopularItemMetric({
    required this.id,
    required this.name,
    this.views = 0,
    this.purchases = 0,
    this.revenue = 0.0,
  });

  @override
  List<Object?> get props => [id, name, views, purchases, revenue];
}

class SearchMetric extends Equatable {
  final String query;
  final int count;

  const SearchMetric({required this.query, required this.count});

  @override
  List<Object?> get props => [query, count];
}

class AnalyticsFunnelMetrics extends Equatable {
  final int totalPageViews;
  final int totalProductViews;
  final int totalCartAdditions;
  final int checkoutsStarted;
  final int purchasesCompleted;
  final double totalRevenue;
  final int totalOrders;

  // Custom Atelier Funnel
  final int customRequestsStarted;
  final int customRequestsCompleted;

  // Appointments Funnel
  final int appointmentsStarted;
  final int appointmentsCompleted;

  // Customer Intelligence
  final int totalCustomers;
  final int repeatCustomers;
  final double retentionRate;

  // Popular rankings
  final List<PopularItemMetric> popularProducts;
  final List<PopularItemMetric> popularCollections;
  final List<SearchMetric> topSearches;

  const AnalyticsFunnelMetrics({
    this.totalPageViews = 0,
    this.totalProductViews = 0,
    this.totalCartAdditions = 0,
    this.checkoutsStarted = 0,
    this.purchasesCompleted = 0,
    this.totalRevenue = 0.0,
    this.totalOrders = 0,
    this.customRequestsStarted = 0,
    this.customRequestsCompleted = 0,
    this.appointmentsStarted = 0,
    this.appointmentsCompleted = 0,
    this.totalCustomers = 0,
    this.repeatCustomers = 0,
    this.retentionRate = 0.0,
    this.popularProducts = const [],
    this.popularCollections = const [],
    this.topSearches = const [],
  });

  /// Conversion rate from Checkout Started -> Purchase Completed
  double get checkoutToPurchaseRate =>
      checkoutsStarted == 0 ? 0.0 : (purchasesCompleted / checkoutsStarted) * 100;

  /// Overall Store Conversion rate (Product View -> Purchase)
  double get storeConversionRate =>
      totalProductViews == 0 ? 0.0 : (purchasesCompleted / totalProductViews) * 100;

  /// Cart Conversion Rate (Product View -> Add to Bag)
  double get cartConversionRate =>
      totalProductViews == 0 ? 0.0 : (totalCartAdditions / totalProductViews) * 100;

  /// Custom Atelier Commission Conversion Rate
  double get customConversionRate => customRequestsStarted == 0
      ? 0.0
      : (customRequestsCompleted / customRequestsStarted) * 100;

  /// Appointment Booking Completion Rate
  double get appointmentCompletionRate =>
      appointmentsStarted == 0 ? 0.0 : (appointmentsCompleted / appointmentsStarted) * 100;

  /// Aliases
  double get conversionRate => storeConversionRate;
  double get checkoutConversionRate => checkoutToPurchaseRate;
  double get appointmentConversionRate => appointmentCompletionRate;

  @override
  List<Object?> get props => [
        totalPageViews,
        totalProductViews,
        totalCartAdditions,
        checkoutsStarted,
        purchasesCompleted,
        totalRevenue,
        totalOrders,
        customRequestsStarted,
        customRequestsCompleted,
        appointmentsStarted,
        appointmentsCompleted,
        totalCustomers,
        repeatCustomers,
        retentionRate,
        popularProducts,
        popularCollections,
        topSearches,
      ];
}
