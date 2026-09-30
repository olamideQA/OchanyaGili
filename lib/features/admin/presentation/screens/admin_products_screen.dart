import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/presentation/widgets/garment_measurements_config_dialog.dart';
import 'package:ochanya_gili/features/shop/data/products_repository.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  void _openCreateDialog([Product? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final slugController = TextEditingController(text: existing?.slug ?? '');
    final priceController = TextEditingController(text: existing != null ? existing.basePrice.toStringAsFixed(0) : '150000');
    final descController = TextEditingController(text: existing?.description ?? '');
    final materialsController = TextEditingController(text: existing?.materials ?? '100% Raw Silk & Wool Crepe');
    final imgController = TextEditingController(text: existing?.primaryImageUrl ?? '');
    ProductType selectedType = existing?.productType ?? ProductType.readyToWear;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Create New Creation' : 'Edit Product'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Garment / Creation Name')),
                      const SizedBox(height: 12),
                      TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug (e.g. ivory-peplum-blazer)')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ProductType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(labelText: 'Product Type'),
                        items: ProductType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.displayName));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Base Price (NGN ₦)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: imgController, decoration: const InputDecoration(labelText: 'Primary Artwork Image URL')),
                      const SizedBox(height: 12),
                      TextField(controller: materialsController, decoration: const InputDecoration(labelText: 'Materials & Textiles')),
                      const SizedBox(height: 12),
                      TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Editorial Description')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(productsRepositoryProvider);
                    final name = nameController.text.trim();
                    final slug = slugController.text.trim().isNotEmpty
                        ? slugController.text.trim()
                        : name.toLowerCase().replaceAll(' ', '-');
                    final price = double.tryParse(priceController.text.trim()) ?? 150000.0;

                    if (existing == null) {
                      final newProduct = Product(
                        id: '',
                        name: name,
                        slug: slug,
                        productType: selectedType,
                        basePrice: price,
                        description: descController.text.trim(),
                        materials: materialsController.text.trim(),
                        images: [
                          ProductImage(
                            id: '',
                            productId: '',
                            // DEMO-SEED: Unsplash placeholder for pitch. Empty when demo disabled.
                            imageUrl: imgController.text.trim().isNotEmpty
                                ? imgController.text.trim()
                                : (DemoConfig.enabled
                                    ? 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/lagos_couture_model.jpg'
                                    : ''),
                            isPrimary: true,
                          ),
                        ],
                      );
                      await repo.createProduct(newProduct);
                    } else {
                      final updated = Product(
                        id: existing.id,
                        name: name,
                        slug: slug,
                        productType: selectedType,
                        basePrice: price,
                        description: descController.text.trim(),
                        materials: materialsController.text.trim(),
                        images: existing.images,
                        variants: existing.variants,
                        isFeatured: existing.isFeatured,
                        isPublished: existing.isPublished,
                        isArchived: existing.isArchived,
                      );
                      await repo.updateProduct(updated);
                    }

                    ref.invalidate(adminProductsProvider);
                    ref.invalidate(allPublishedProductsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Creation'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final productsAsync = ref.watch(adminProductsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Products Management', style: TextStyle(color: colors.primaryText)),
        backgroundColor: colors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('NEW CREATION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
              ),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.surfaceVariant,
                  backgroundImage: product.primaryImageUrl.isNotEmpty ? NetworkImage(product.primaryImageUrl) : null,
                  child: product.primaryImageUrl.isEmpty ? Icon(Icons.checkroom, color: colors.secondaryText) : null,
                ),
                title: Row(
                  children: [
                    Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: colors.accentVariant.withValues(alpha: 0.15),
                      child: Text(
                        product.productType.displayName.toUpperCase(),
                        style: TextStyle(color: colors.accentVariant, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Text('${currencyFormatter.format(product.basePrice)}  •  ${product.isArchived ? "ARCHIVED" : "PUBLISHED"}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product.productType.isMadeToOrder || product.productType.isCustom)
                      IconButton(
                        icon: Icon(Icons.straighten_outlined, color: colors.accentVariant),
                        tooltip: 'Configure Required Measurements',
                        onPressed: () {
                          GarmentMeasurementsConfigDialog.show(
                            context,
                            product: product,
                            onSaved: () {
                              ref.invalidate(adminProductsProvider);
                              ref.invalidate(allPublishedProductsProvider);
                            },
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: colors.primaryText),
                      onPressed: () => _openCreateDialog(product),
                    ),
                    IconButton(
                      icon: Icon(
                        product.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        color: product.isArchived ? colors.accentVariant : colors.secondaryText,
                      ),
                      tooltip: product.isArchived ? 'Restore' : 'Archive',
                      onPressed: () async {
                        final repo = ref.read(productsRepositoryProvider);
                        await repo.archiveProduct(product.id, !product.isArchived);
                        ref.invalidate(adminProductsProvider);
                        ref.invalidate(allPublishedProductsProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
        error: (err, stack) => Center(child: Text('Error loading products: $err')),
      ),
    );
  }
}
