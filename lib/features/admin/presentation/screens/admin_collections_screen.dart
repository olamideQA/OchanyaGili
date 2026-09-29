import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/collections/data/collections_repository.dart';
import 'package:ochanya_gili/features/collections/domain/models/collection_item.dart';

class AdminCollectionsScreen extends ConsumerStatefulWidget {
  const AdminCollectionsScreen({super.key});

  @override
  ConsumerState<AdminCollectionsScreen> createState() => _AdminCollectionsScreenState();
}

class _AdminCollectionsScreenState extends ConsumerState<AdminCollectionsScreen> {
  void _openCreateDialog([CollectionItem? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final slugController = TextEditingController(text: existing?.slug ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final coverController = TextEditingController(text: existing?.coverImageUrl ?? '');
    final seasonController = TextEditingController(text: existing?.season ?? 'Autumn / Winter');
    final yearController = TextEditingController(text: (existing?.year ?? 2026).toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Create New Collection' : 'Edit Collection'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Collection Name')),
                  const SizedBox(height: 12),
                  TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug (e.g. autumn-2026)')),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  TextField(controller: coverController, decoration: const InputDecoration(labelText: 'Cover Image URL')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: seasonController, decoration: const InputDecoration(labelText: 'Season'))),
                      const SizedBox(width: 16),
                      Expanded(child: TextField(controller: yearController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(collectionsRepositoryProvider);
                final name = nameController.text.trim();
                final slug = slugController.text.trim().isNotEmpty
                    ? slugController.text.trim()
                    : name.toLowerCase().replaceAll(' ', '-');

                if (existing == null) {
                  final newItem = CollectionItem(
                    id: '',
                    name: name,
                    slug: slug,
                    description: descController.text.trim(),
                    coverImageUrl: coverController.text.trim(),
                    season: seasonController.text.trim(),
                    year: int.tryParse(yearController.text.trim()) ?? 2026,
                    isPublished: true,
                    isFeatured: false,
                  );
                  await repo.createCollection(newItem);
                } else {
                  final updated = existing.copyWith(
                    name: name,
                    slug: slug,
                    description: descController.text.trim(),
                    coverImageUrl: coverController.text.trim(),
                    season: seasonController.text.trim(),
                    year: int.tryParse(yearController.text.trim()) ?? existing.year,
                  );
                  await repo.updateCollection(updated);
                }

                ref.invalidate(adminCollectionsProvider);
                ref.invalidate(publishedCollectionsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Collection'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final collectionsAsync = ref.watch(adminCollectionsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Collections Management', style: TextStyle(color: colors.primaryText)),
        backgroundColor: colors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('NEW COLLECTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
              ),
            ),
          ),
        ],
      ),
      body: collectionsAsync.when(
        data: (collections) {
          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: collections.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final col = collections[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.surfaceVariant,
                  backgroundImage: col.coverImageUrl != null ? NetworkImage(col.coverImageUrl!) : null,
                  child: col.coverImageUrl == null ? Icon(Icons.collections, color: colors.secondaryText) : null,
                ),
                title: Text(col.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
                subtitle: Text('${col.season ?? ''} ${col.year ?? ''}  •  ${col.isArchived ? "ARCHIVED" : "ACTIVE"}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Featured Toggle
                    IconButton(
                      icon: Icon(
                        col.isFeatured ? Icons.star : Icons.star_border,
                        color: col.isFeatured ? colors.accentVariant : colors.secondaryText,
                      ),
                      tooltip: col.isFeatured ? 'Featured on Homepage' : 'Mark as Featured',
                      onPressed: () async {
                        final repo = ref.read(collectionsRepositoryProvider);
                        await repo.toggleFeatured(col.id, !col.isFeatured);
                        ref.invalidate(adminCollectionsProvider);
                        ref.invalidate(publishedCollectionsProvider);
                      },
                    ),
                    // Edit
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: colors.primaryText),
                      onPressed: () => _openCreateDialog(col),
                    ),
                    // Archive / Unarchive
                    IconButton(
                      icon: Icon(
                        col.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        color: col.isArchived ? colors.accentVariant : colors.secondaryText,
                      ),
                      tooltip: col.isArchived ? 'Restore' : 'Archive',
                      onPressed: () async {
                        final repo = ref.read(collectionsRepositoryProvider);
                        await repo.archiveCollection(col.id, !col.isArchived);
                        ref.invalidate(adminCollectionsProvider);
                        ref.invalidate(publishedCollectionsProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
        error: (err, stack) => Center(child: Text('Error loading collections: $err')),
      ),
    );
  }
}
