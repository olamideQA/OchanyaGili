import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/lookbook/data/lookbook_repository.dart';
import 'package:ochanya_gili/features/lookbook/domain/models/lookbook_entry.dart';

class AdminLookbookScreen extends ConsumerStatefulWidget {
  const AdminLookbookScreen({super.key});

  @override
  ConsumerState<AdminLookbookScreen> createState() => _AdminLookbookScreenState();
}

class _AdminLookbookScreenState extends ConsumerState<AdminLookbookScreen> {
  void _openCreateDialog([LookbookEntry? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final slugController = TextEditingController(text: existing?.slug ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final coverController = TextEditingController(text: existing?.coverImageUrl ?? '');
    final notesController = TextEditingController(text: existing?.designerNotes ?? '');
    final modelController = TextEditingController(text: existing?.modelName ?? '');
    final photoController = TextEditingController(text: existing?.photographer ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Lookbook Entry' : 'Edit Lookbook Entry'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Look Title (e.g. Look 05 — Ivory Peplum)')),
                  const SizedBox(height: 12),
                  TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug (e.g. look-05-ivory-peplum)')),
                  const SizedBox(height: 12),
                  TextField(controller: coverController, decoration: const InputDecoration(labelText: 'High-Res Artwork Image URL')),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Designer Notes / Quotation')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Model Name'))),
                      const SizedBox(width: 16),
                      Expanded(child: TextField(controller: photoController, decoration: const InputDecoration(labelText: 'Photographer'))),
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
                final repo = ref.read(lookbookRepositoryProvider);
                final title = titleController.text.trim();
                final slug = slugController.text.trim().isNotEmpty
                    ? slugController.text.trim()
                    : title.toLowerCase().replaceAll(' ', '-');

                if (existing == null) {
                  final newEntry = LookbookEntry(
                    id: '',
                    title: title,
                    slug: slug,
                    description: descController.text.trim(),
                    coverImageUrl: coverController.text.trim(),
                    fullImageUrl: coverController.text.trim(),
                    designerNotes: notesController.text.trim(),
                    modelName: modelController.text.trim(),
                    photographer: photoController.text.trim(),
                    isPublished: true,
                  );
                  await repo.createLookbook(newEntry);
                } else {
                  final updated = existing.copyWith(
                    title: title,
                    slug: slug,
                    description: descController.text.trim(),
                    coverImageUrl: coverController.text.trim(),
                    fullImageUrl: coverController.text.trim(),
                    designerNotes: notesController.text.trim(),
                    modelName: modelController.text.trim(),
                    photographer: photoController.text.trim(),
                  );
                  await repo.updateLookbook(updated);
                }

                ref.invalidate(adminLookbooksProvider);
                ref.invalidate(publishedLookbooksProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Look'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final looksAsync = ref.watch(adminLookbooksProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Lookbook Management', style: TextStyle(color: colors.primaryText)),
        backgroundColor: colors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('NEW LOOK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
              ),
            ),
          ),
        ],
      ),
      body: looksAsync.when(
        data: (looks) {
          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: looks.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final look = looks[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.surfaceVariant,
                  backgroundImage: NetworkImage(look.coverImageUrl),
                ),
                title: Text(look.title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
                subtitle: Text('Model: ${look.modelName ?? "N/A"}  •  Photo: ${look.photographer ?? "N/A"}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: colors.primaryText),
                      onPressed: () => _openCreateDialog(look),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colors.error),
                      onPressed: () async {
                        final repo = ref.read(lookbookRepositoryProvider);
                        await repo.deleteLookbook(look.id);
                        ref.invalidate(adminLookbooksProvider);
                        ref.invalidate(publishedLookbooksProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
        error: (err, stack) => Center(child: Text('Error loading lookbook: $err')),
      ),
    );
  }
}
