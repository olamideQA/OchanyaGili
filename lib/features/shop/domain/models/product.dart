import 'package:equatable/equatable.dart';

enum ProductType {
  readyToWear,
  madeToOrder,
  custom,
  accessory;

  static ProductType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'made_to_order':
      case 'madetoorder':
        return ProductType.madeToOrder;
      case 'custom':
        return ProductType.custom;
      case 'accessory':
        return ProductType.accessory;
      case 'ready_to_wear':
      case 'readytowear':
      default:
        return ProductType.readyToWear;
    }
  }

  String toJson() {
    switch (this) {
      case ProductType.madeToOrder:
        return 'made_to_order';
      case ProductType.custom:
        return 'custom';
      case ProductType.accessory:
        return 'accessory';
      case ProductType.readyToWear:
        return 'ready_to_wear';
    }
  }

  String get displayName {
    switch (this) {
      case ProductType.readyToWear:
        return 'Ready-to-Wear';
      case ProductType.madeToOrder:
        return 'Made-to-Order';
      case ProductType.custom:
        return 'Bespoke Couture';
      case ProductType.accessory:
        return 'Atelier Accessory';
    }
  }

  bool get isCustom => this == ProductType.custom;
  bool get isMadeToOrder => this == ProductType.madeToOrder;
  bool get isReadyToWear => this == ProductType.readyToWear;
  bool get isAccessory => this == ProductType.accessory;
  bool get requiresMeasurements => this == ProductType.madeToOrder || this == ProductType.custom;

  String get ctaLabel {
    switch (this) {
      case ProductType.readyToWear:
      case ProductType.accessory:
        return 'ADD TO BAG';
      case ProductType.madeToOrder:
        return 'SELECT MEASUREMENTS & ORDER';
      case ProductType.custom:
        return 'REQUEST ATELIER CUSTOMIZATION';
    }
  }
}

class ProductVariant extends Equatable {
  final String id;
  final String productId;
  final String? size;
  final String? colour;
  final String? sku;
  final double? priceOverride;
  final int stockQuantity;
  final bool isAvailable;

  const ProductVariant({
    required this.id,
    required this.productId,
    this.size,
    this.colour,
    this.sku,
    this.priceOverride,
    this.stockQuantity = 0,
    this.isAvailable = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      size: json['size'] as String?,
      colour: json['colour'] as String?,
      sku: json['sku'] as String?,
      priceOverride: (json['price_override'] as num?)?.toDouble(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'size': size,
      'colour': colour,
      'sku': sku,
      'price_override': priceOverride,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
    };
  }

  @override
  List<Object?> get props => [id, productId, size, colour, sku, priceOverride, stockQuantity, isAvailable];
}

class ProductImage extends Equatable {
  final String id;
  final String productId;
  final String imageUrl;
  final String? altText;
  final bool isPrimary;
  final int sortOrder;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.altText,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      altText: json['alt_text'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'alt_text': altText,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, productId, imageUrl, altText, isPrimary, sortOrder];
}

class Product extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final ProductType productType;
  final String? categoryId;
  final String? categoryName;
  final String? collectionId;
  final String? collectionName;
  final double basePrice;
  final double? compareAtPrice;
  final String? materials;
  final String? careInstructions;
  final String? sizeGuide;
  final int? productionTimeDays;
  final String? deliveryEstimate;
  final bool isFeatured;
  final bool isPublished;
  final bool isArchived;
  final List<String> requiredMeasurements;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.productType,
    this.categoryId,
    this.categoryName,
    this.collectionId,
    this.collectionName,
    required this.basePrice,
    this.compareAtPrice,
    this.materials,
    this.careInstructions,
    this.sizeGuide,
    this.productionTimeDays,
    this.deliveryEstimate,
    this.isFeatured = false,
    this.isPublished = true,
    this.isArchived = false,
    this.requiredMeasurements = const [],
    this.images = const [],
    this.variants = const [],
  });

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    final primary = images.firstWhere((img) => img.isPrimary, orElse: () => images.first);
    return primary.imageUrl;
  }

  List<String> get availableSizes {
    return variants
        .map((v) => v.size)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
  }

  List<String> get availableColours {
    return variants
        .map((v) => v.colour)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
  }

  int get totalStock {
    if (variants.isEmpty) return 0;
    return variants.fold(0, (sum, v) => sum + v.stockQuantity);
  }

  bool get inStock {
    if (productType.isMadeToOrder || productType.isCustom) return true; // produced on demand
    return totalStock > 0;
  }

  /// Returns explicit required measurements if configured by designer,
  /// or intelligent defaults based on product type.
  List<String> get effectiveRequiredMeasurements {
    if (requiredMeasurements.isNotEmpty) {
      return requiredMeasurements;
    }
    if (productType.isMadeToOrder) {
      return const ['shoulder', 'bust', 'under_bust', 'waist', 'hip', 'front_length', 'dress_length'];
    }
    if (productType.isCustom) {
      return const [
        'shoulder', 'bust', 'under_bust', 'waist', 'hip',
        'armhole', 'sleeve_length', 'bicep', 'wrist',
        'back_length', 'front_length', 'dress_length',
        'trouser_waist', 'trouser_hip', 'trouser_length',
        'inseam', 'thigh', 'neck',
      ];
    }
    return const [];
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['product_images'] as List<dynamic>? ?? [];
    final images = rawImages.map((e) => ProductImage.fromJson(e as Map<String, dynamic>)).toList();

    final rawVariants = json['product_variants'] as List<dynamic>? ?? [];
    final variants = rawVariants.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>)).toList();

    final rawMeasurements = json['required_measurements'] as List<dynamic>? ?? [];
    final requiredMeasurements = rawMeasurements.map((e) => e.toString()).toList();

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      productType: ProductType.fromString(json['product_type'] as String? ?? 'ready_to_wear'),
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      collectionId: json['collection_id'] as String?,
      collectionName: json['collection_name'] as String?,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (json['compare_at_price'] as num?)?.toDouble(),
      materials: json['materials'] as String?,
      careInstructions: json['care_instructions'] as String?,
      sizeGuide: json['size_guide'] as String?,
      productionTimeDays: (json['production_time_days'] as num?)?.toInt(),
      deliveryEstimate: json['delivery_estimate'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      isArchived: json['is_archived'] as bool? ?? false,
      requiredMeasurements: requiredMeasurements,
      images: images,
      variants: variants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'product_type': productType.toJson(),
      'category_id': categoryId,
      'collection_id': collectionId,
      'base_price': basePrice,
      'compare_at_price': compareAtPrice,
      'materials': materials,
      'care_instructions': careInstructions,
      'size_guide': sizeGuide,
      'production_time_days': productionTimeDays,
      'delivery_estimate': deliveryEstimate,
      'is_featured': isFeatured,
      'is_published': isPublished,
      'is_archived': isArchived,
      'required_measurements': requiredMeasurements,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        shortDescription,
        productType,
        categoryId,
        collectionId,
        basePrice,
        compareAtPrice,
        materials,
        careInstructions,
        sizeGuide,
        productionTimeDays,
        deliveryEstimate,
        isFeatured,
        isPublished,
        isArchived,
        requiredMeasurements,
        images,
        variants,
      ];
}

class PaginatedProducts extends Equatable {
  final List<Product> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedProducts({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [items, totalCount, page, pageSize];
}

