import 'package:equatable/equatable.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

enum ShopSortOption {
  featured,
  newest,
  priceAsc,
  priceDesc;

  String get displayName {
    switch (this) {
      case ShopSortOption.featured:
        return 'Featured';
      case ShopSortOption.newest:
        return 'Newest Arrivals';
      case ShopSortOption.priceAsc:
        return 'Price: Low to High';
      case ShopSortOption.priceDesc:
        return 'Price: High to Low';
    }
  }
}

class ShopFilterState extends Equatable {
  final String? category;
  final String? collection;
  final ProductType? productType;
  final String? size;
  final String? colour;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final String? searchQuery;
  final ShopSortOption sortOption;
  final int page;
  final int pageSize;

  const ShopFilterState({
    this.category,
    this.collection,
    this.productType,
    this.size,
    this.colour,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.searchQuery,
    this.sortOption = ShopSortOption.featured,
    this.page = 1,
    this.pageSize = 9,
  });

  ShopFilterState copyWith({
    String? category,
    String? collection,
    ProductType? productType,
    String? size,
    String? colour,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? searchQuery,
    ShopSortOption? sortOption,
    int? page,
    int? pageSize,
    bool clearCategory = false,
    bool clearCollection = false,
    bool clearProductType = false,
    bool clearSize = false,
    bool clearColour = false,
  }) {
    return ShopFilterState(
      category: clearCategory ? null : (category ?? this.category),
      collection: clearCollection ? null : (collection ?? this.collection),
      productType: clearProductType ? null : (productType ?? this.productType),
      size: clearSize ? null : (size ?? this.size),
      colour: clearColour ? null : (colour ?? this.colour),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      collection != null ||
      productType != null ||
      size != null ||
      colour != null ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  @override
  List<Object?> get props => [
        category,
        collection,
        productType,
        size,
        colour,
        minPrice,
        maxPrice,
        inStockOnly,
        searchQuery,
        sortOption,
        page,
        pageSize,
      ];
}
