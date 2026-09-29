import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';

class AdminJournalScreen extends ConsumerStatefulWidget {
  const AdminJournalScreen({super.key});

  @override
  ConsumerState<AdminJournalScreen> createState() => _AdminJournalScreenState();
}

class _AdminJournalScreenState extends ConsumerState<AdminJournalScreen> {
  void _openCreateArticleDialog(BuildContext context, AppColorTokens colors) {
    final titleCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final excerptCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final coverUrlCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(
                'NEW JOURNAL EDITORIAL ENTRY',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        onChanged: (val) {
                          slugCtrl.text = val
                              .toLowerCase()
                              .trim()
                              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                              .replaceAll(RegExp(r'^-|-$'), '');
                        },
                        decoration: InputDecoration(
                          labelText: 'ARTICLE TITLE *',
                          hintText: 'e.g. The Architecture of West African Haute Couture',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: slugCtrl,
                        decoration: InputDecoration(
                          labelText: 'SLUG / PERMALINK *',
                          hintText: 'the-architecture-of-west-african-haute-couture',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: excerptCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'EDITORIAL EXCERPT *',
                          hintText: 'A brief synopsis for journal cards and social shares...',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: coverUrlCtrl,
                        decoration: InputDecoration(
                          labelText: 'COVER IMAGE CDN URL',
                          hintText: 'https://...',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: tagsCtrl,
                        decoration: InputDecoration(
                          labelText: 'TAGS (COMMA SEPARATED)',
                          hintText: 'Couture, Silk, Runway, Heritage',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'FULL ARTICLE CONTENT (MARKDOWN) *',
                          hintText: 'Write or paste the editorial narrative...',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: Text('CANCEL', style: TextStyle(color: colors.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final slug = slugCtrl.text.trim();
                          final excerpt = excerptCtrl.text.trim();
                          final content = contentCtrl.text.trim();

                          if (title.isEmpty || slug.isEmpty || content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill out Title, Slug, and Content')),
                            );
                            return;
                          }

                          final tags = tagsCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          setDialogState(() => isSubmitting = true);
                          try {
                            final post = JournalPost(
                              id: '',
                              title: title,
                              slug: slug,
                              excerpt: excerpt,
                              content: content,
                              coverImageUrl: coverUrlCtrl.text.trim(),
                              isPublished: true,
                              publishedAt: DateTime.now(),
                              tags: tags,
                            );

                            await ref.read(adminRepositoryProvider).createJournalPost(post);
                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ref.invalidate(adminJournalPostsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Editorial "$title" published to Journal'),
                                  backgroundColor: colors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error publishing article: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryText,
                    foregroundColor: colors.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('PUBLISH ENTRY', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final postsAsync = ref.watch(adminJournalPostsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EDITORIAL JOURNAL MANAGER',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atelier publications, stories of heritage, press, and couture chronicles',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(adminJournalPostsProvider),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('REFRESH'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.border),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateArticleDialog(context, colors),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('NEW ARTICLE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryText,
                        foregroundColor: colors.surface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Posts Table
            postsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading journal: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(60),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            'No editorial posts created yet.',
                            style: TextStyle(color: colors.secondaryText, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _openCreateArticleDialog(context, colors),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryText,
                              foregroundColor: colors.surface,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('CREATE FIRST ARTICLE'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        color: colors.surfaceVariant,
                        child: Row(
                          children: [
                            Expanded(flex: 4, child: _HeaderCell('ARTICLE TITLE & SLUG', colors)),
                            Expanded(flex: 3, child: _HeaderCell('TAGS', colors)),
                            Expanded(flex: 2, child: _HeaderCell('PUBLISHED DATE', colors)),
                            Expanded(flex: 2, child: _HeaderCell('STATUS', colors, align: TextAlign.right)),
                          ],
                        ),
                      ),
                      Divider(color: colors.border, height: 1),

                      // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, index) {
                          final p = posts[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                // Title & slug
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '/journal/${p.slug}',
                                        style: TextStyle(fontSize: 12, color: colors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),

                                // Tags
                                Expanded(
                                  flex: 3,
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: p.tags
                                        .map(
                                          (t) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            color: colors.surfaceVariant,
                                            child: Text(
                                              t,
                                              style: TextStyle(fontSize: 10, color: colors.primaryText),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),

                                // Published date
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.publishedAt != null
                                        ? DateFormat('dd MMM yyyy').format(p.publishedAt!)
                                        : 'Draft',
                                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                                  ),
                                ),

                                // Switch status
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          p.isPublished ? 'PUBLISHED' : 'DRAFT',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: p.isPublished ? colors.success : colors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: p.isPublished,
                                          activeThumbColor: colors.primaryText,
                                          onChanged: (val) async {
                                            await ref
                                                .read(adminRepositoryProvider)
                                                .toggleJournalPublish(p.id, val);
                                            ref.invalidate(adminJournalPostsProvider);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  final AppColorTokens colors;
  final TextAlign align;

  const _HeaderCell(this.title, this.colors, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: align,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: colors.primaryText,
      ),
    );
  }
}
