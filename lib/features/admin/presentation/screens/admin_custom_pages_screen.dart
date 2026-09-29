import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/custom_page.dart';

class AdminCustomPagesScreen extends ConsumerStatefulWidget {
  const AdminCustomPagesScreen({super.key});

  @override
  ConsumerState<AdminCustomPagesScreen> createState() => _AdminCustomPagesScreenState();
}

class _AdminCustomPagesScreenState extends ConsumerState<AdminCustomPagesScreen> {
  void _openPageEditor({CustomPage? page}) {
    final titleCtrl = TextEditingController(text: page?.title ?? '');
    final slugCtrl = TextEditingController(text: page?.slug ?? '');
    final descCtrl = TextEditingController(text: page?.metaDescription ?? '');
    final contentCtrl = TextEditingController(text: page?.content ?? '');
    bool isPublished = page?.isPublished ?? true;
    bool isSubmitting = false;

    String slugify(String text) {
      return text
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = Theme.of(ctx).extension<AppColorTokens>()!;
          return AlertDialog(
            title: Text(
              page == null ? 'Create Custom Page' : 'Edit Custom Page',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Page Title *',
                        hintText: 'e.g. Private Client Services, Sustainability & Heritage',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        if (page == null && slugCtrl.text.isEmpty) {
                          slugCtrl.text = slugify(val);
                          setDialogState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Slug * (accessed at /p/slug)',
                        hintText: 'e.g. private-client-services',
                        prefixText: '/p/',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Meta Description (SEO & Subtitle)',
                        hintText: 'Brief summary displayed beneath the page header...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Page Editorial Content *',
                        hintText: 'Enter paragraphs of editorial text. Use double returns for new paragraphs.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Published on Storefront'),
                      subtitle: const Text('When disabled, this page will not be accessible to public visitors.'),
                      value: isPublished,
                      activeThumbColor: colors.accentVariant,
                      onChanged: (v) => setDialogState(() => isPublished = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final title = titleCtrl.text.trim();
                        final slug = slugCtrl.text.trim().toLowerCase();
                        final content = contentCtrl.text.trim();
                        final desc = descCtrl.text.trim();

                        if (title.isEmpty || slug.isEmpty || content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields.')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final newPage = CustomPage(
                            id: page?.id ?? '',
                            title: title,
                            slug: slug,
                            content: content,
                            metaDescription: desc.isNotEmpty ? desc : null,
                            isPublished: isPublished,
                          );

                          await ref.read(cmsRepositoryProvider).saveCustomPage(newPage);
                          ref.invalidate(customPagesProvider);

                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Page "$title" saved successfully!'),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                          }

                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to save page: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(page == null ? 'Create Page' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deletePage(CustomPage page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Page?'),
        content: Text('Are you sure you want to delete "${page.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(cmsRepositoryProvider).deleteCustomPage(page.id);
        ref.invalidate(customPagesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Page "${page.title}" deleted.'), backgroundColor: Colors.black87),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final pagesAsync = ref.watch(customPagesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'CUSTOM EDITORIAL PAGES STUDIO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STANDALONE MAISON PAGES',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.0,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Publish custom narrative pages accessible via /p/:slug (e.g. VIP Concierge, Sustainability, Care Guides).',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: () => _openPageEditor(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('CREATE NEW PAGE'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pages List
                pagesAsync.when(
                  loading: () => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(color: colors.accentVariant),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Text('Error loading custom pages: $e', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  data: (pages) {
                    if (pages.isEmpty) {
                      return Card(
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: colors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              Icon(Icons.article_outlined, size: 48, color: colors.accentVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No Custom Pages Created Yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "CREATE NEW PAGE" above to write your first bespoke editorial story.',
                                style: TextStyle(color: colors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final p in pages)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Row(
                                children: [
                                  Text(
                                    p.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: colors.text,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.isPublished
                                          ? colors.success.withValues(alpha: 0.15)
                                          : colors.border,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      p.isPublished ? 'PUBLISHED' : 'DRAFT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: p.isPublished ? colors.success : colors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'URL: /p/${p.slug}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: colors.accentVariant,
                                    ),
                                  ),
                                  if (p.metaDescription != null && p.metaDescription!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      p.metaDescription!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.text,
                                      side: BorderSide(color: colors.border),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => context.go('/p/${p.slug}'),
                                    icon: const Icon(Icons.open_in_new, size: 14),
                                    label: const Text('View Page', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Edit Page',
                                    onPressed: () => _openPageEditor(page: p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    tooltip: 'Delete Page',
                                    onPressed: () => _deletePage(p),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
