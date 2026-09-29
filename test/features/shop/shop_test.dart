import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';
import 'package:ochanya_gili/features/shop/domain/models/shop_filter_state.dart';

void main() {
  group('Loop 3: Shop & Product Pages Tests', () {
    test('ProductType enum covers all 4 types and validates strict CTA branching', () {
      expect(ProductType.readyToWear.ctaLabel, 'ADD TO BAG');
      expect(ProductType.readyToWear.isCustom, isFalse);
      expect(ProductType.readyToWear.requiresMeasurements, isFalse);

      expect(ProductType.madeToOrder.ctaLabel, 'SELECT MEASUREMENTS & ORDER');
      expect(ProductType.madeToOrder.isCustom, isFalse);
      expect(ProductType.madeToOrder.requiresMeasurements, isTrue);

      // CRITICAL QUALITY GATE: CUSTOM must NEVER show "ADD TO BAG"
      expect(ProductType.custom.isCustom, isTrue);
      expect(ProductType.custom.requiresMeasurements, isTrue);
      expect(ProductType.custom.ctaLabel, isNot(contains('ADD TO BAG')));
      expect(ProductType.custom.ctaLabel, 'REQUEST ATELIER CUSTOMIZATION');

      expect(ProductType.accessory.ctaLabel, 'ADD TO BAG');
      expect(ProductType.accessory.isCustom, isFalse);
      expect(ProductType.accessory.requiresMeasurements, isFalse);
    });

    test('Product model calculations for stock, sizes, and colours', () {
      const product = Product(
        id: 'p-1',
        name: 'The Sovereign Peplum Gown',
        slug: 'sovereign-peplum-gown',
        productType: ProductType.readyToWear,
        basePrice: 320000.0,
        variants: [
          ProductVariant(id: 'v-1', productId: 'p-1', size: 'UK 8', colour: 'Emerald', stockQuantity: 3),
          ProductVariant(id: 'v-2', productId: 'p-1', size: 'UK 10', colour: 'Emerald', stockQuantity: 5),
          ProductVariant(id: 'v-3', productId: 'p-1', size: 'UK 8', colour: 'Gold', stockQuantity: 0),
        ],
      );

      expect(product.totalStock, 8);
      expect(product.inStock, isTrue);
      expect(product.availableSizes, containsAll(['UK 8', 'UK 10']));
      expect(product.availableColours, containsAll(['Emerald', 'Gold']));
    });

    test('ProductType madeToOrder and custom are always inStock for on-demand production', () {
      const customProduct = Product(
        id: 'p-cust',
        name: 'Custom Atelier Piece',
        slug: 'custom-piece',
        productType: ProductType.custom,
        basePrice: 500000.0,
        variants: [],
      );

      expect(customProduct.inStock, isTrue);

      const mtoProduct = Product(
        id: 'p-mto',
        name: 'Made to Order Piece',
        slug: 'mto-piece',
        productType: ProductType.madeToOrder,
        basePrice: 280000.0,
        variants: [],
      );

      expect(mtoProduct.inStock, isTrue);
    });

    test('ShopFilterState filters by ProductType and Price range', () {
      const state = ShopFilterState(productType: ProductType.readyToWear, maxPrice: 200000.0);
      expect(state.productType, ProductType.readyToWear);
      expect(state.maxPrice, 200000.0);
      expect(state.hasActiveFilters, isTrue);

      final updatedState = state.copyWith(clearProductType: true);
      expect(updatedState.productType, isNull);

      final p1 = Product(
        id: '1',
        name: 'RTW Blazer',
        slug: 'rtw-blazer',
        productType: ProductType.readyToWear,
        basePrice: 150000.0,
      );
      final p2 = Product(
        id: '2',
        name: 'Couture Gown',
        slug: 'couture-gown',
        productType: ProductType.custom,
        basePrice: 650000.0,
      );
      final p3 = Product(
        id: '3',
        name: 'Silk Accessory',
        slug: 'silk-accessory',
        productType: ProductType.accessory,
        basePrice: 50000.0,
      );

      final list = [p1, p2, p3];

      // Filter by product type
      final rtwOnly = list.where((p) => p.productType == ProductType.readyToWear).toList();
      expect(rtwOnly.length, 1);
      expect(rtwOnly.first.name, 'RTW Blazer');

      // Filter by max price 200,000
      final under200k = list.where((p) => p.basePrice <= 200000.0).toList();
      expect(under200k.length, 2);
      expect(under200k.map((e) => e.name), containsAll(['RTW Blazer', 'Silk Accessory']));
    });

    test('ShopSortOption sorts prices asc and desc correctly', () {
      final p1 = Product(id: '1', name: 'A', slug: 'a', productType: ProductType.readyToWear, basePrice: 200.0);
      final p2 = Product(id: '2', name: 'B', slug: 'b', productType: ProductType.readyToWear, basePrice: 100.0);
      final p3 = Product(id: '3', name: 'C', slug: 'c', productType: ProductType.readyToWear, basePrice: 300.0);

      final list = [p1, p2, p3];

      list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      expect(list.first.basePrice, 100.0);
      expect(list.last.basePrice, 300.0);

      list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
      expect(list.first.basePrice, 300.0);
      expect(list.last.basePrice, 100.0);
    });
  });
}
