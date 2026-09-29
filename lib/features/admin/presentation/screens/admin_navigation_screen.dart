import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/brand_header.dart';
import 'package:ochanya_gili/features/cms/domain/models/navigation_item.dart';

class AdminNavigationScreen extends ConsumerStatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  ConsumerState<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends ConsumerState<AdminNavigationScreen> {
  // Brand Header state
  final _brandNameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _taglineController = TextEditingController();
  final _announcementController = TextEditingController();
  bool _showAnnouncement = true;
  bool _isSavingHeader = false;
  bool _headerLoaded = false;

  // Nav Items state
  List<NavigationItem> _navItems = [];
  bool _isSavingNav = false;
  bool _navLoaded = false;

  @override
  void dispose() {
    _brandNameController.dispose();
    _logoUrlController.dispose();
    _taglineController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  void _initHeader(BrandHeader header) {
    if (!_headerLoaded) {
      _brandNameController.text = header.brandName;
      _logoUrlController.text = header.logoUrl;
      _taglineController.text = header.tagline;
      _announcementController.text = header.announcementText;
      _showAnnouncement = header.showAnnouncement;
      _headerLoaded = true;
    }
  }

  void _initNav(List<NavigationItem> items) {
    if (!_navLoaded) {
      _navItems = List.from(items)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _navLoaded = true;
    }
  }

  Future<void> _saveHeader() async {
    setState(() => _isSavingHeader = true);
    try {
      final updated = BrandHeader(
        brandName: _brandNameController.text.trim().isEmpty ? 'OCHANYA GILI' : _brandNameController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        tagline: _taglineController.text.trim(),
        announcementText: _announcementController.text.trim(),
        showAnnouncement: _showAnnouncement,
      );

      await ref.read(cmsRepositoryProvider).saveBrandHeader(updated);
      ref.invalidate(brandHeaderProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand header & announcement published successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save header: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingHeader = false);
    }
  }

  Future<void> _saveNavMenu() async {
    setState(() => _isSavingNav = true);
    try {
      // Re-assign sequential sort orders
      final reindexed = <NavigationItem>[];
      for (int i = 0; i < _navItems.length; i++) {
        reindexed.add(_navItems[i].copyWith(sortOrder: i));
      }

      await ref.read(cmsRepositoryProvider).saveNavigationItems(reindexed);
      ref.invalidate(navigationItemsProvider);

      if (mounted) {
        setState(() => _navItems = reindexed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation menu published to storefront!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save menu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNav = false);
    }
  }

  void _showAddEditDialog({NavigationItem? item, int? index}) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final pathCtrl = TextEditingController(text: item?.path ?? '/');
    bool isExternal = item?.isExternal ?? false;
    bool isVisible = item?.isVisible ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = Theme.of(ctx).extension<AppColorTokens>()!;
          return AlertDialog(
            title: Text(
              item == null ? 'Add Navigation Item' : 'Edit Navigation Item',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Menu Title',
                      hintText: 'e.g. Bespoke Atelier, Bridal, Archive',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pathCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Route or URL',
                      hintText: 'e.g. /collections, /p/sustainability, https://...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Visible on Storefront'),
                    value: isVisible,
                    activeThumbColor: colors.accentVariant,
                    onChanged: (v) => setDialogState(() => isVisible = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('External Website Link'),
                    subtitle: const Text('Opens in a new browser tab'),
                    value: isExternal,
                    activeThumbColor: colors.accentVariant,
                    onChanged: (v) => setDialogState(() => isExternal = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final path = pathCtrl.text.trim();
                  if (title.isEmpty) return;

                  setState(() {
                    if (item == null) {
                      _navItems.add(NavigationItem(
                        id: 'nav-${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        path: path,
                        sortOrder: _navItems.length,
                        isVisible: isVisible,
                        isExternal: isExternal,
                      ));
                    } else if (index != null) {
                      _navItems[index] = item.copyWith(
                        title: title,
                        path: path,
                        isVisible: isVisible,
                        isExternal: isExternal,
                      );
                    }
                  });
                  Navigator.of(ctx).pop();
                },
                child: Text(item == null ? 'Add Tab' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final headerAsync = ref.watch(brandHeaderProvider);
    final navAsync = ref.watch(navigationItemsProvider);

    headerAsync.whenData((h) => _initHeader(h));
    navAsync.whenData((n) => _initNav(n));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'STOREFRONT HEADER & NAVIGATION STUDIO',
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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Brand Identity & Header
                Card(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.brush_outlined, color: colors.accentVariant),
                            const SizedBox(width: 12),
                            Text(
                              'MAISON BRAND IDENTITY & LOGO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1.0,
                                color: colors.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configure the store brand title, image logo, subtitle, and top announcement ticker.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _brandNameController,
                          decoration: const InputDecoration(
                            labelText: 'Brand Name',
                            hintText: 'e.g. OCHANYA GILI',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _logoUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Logo Image URL (Optional)',
                            hintText: 'https://...',
                            helperText: 'Leave blank to use pure typographic brand styling',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (_logoUrlController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                const Text('Logo Preview: ', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 12),
                                Image.network(
                                  _logoUrlController.text.trim(),
                                  height: 36,
                                  errorBuilder: (context, error, stackTrace) => const Text(
                                    'Invalid Image URL',
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _taglineController,
                          decoration: const InputDecoration(
                            labelText: 'Maison Tagline',
                            hintText: 'e.g. HAUTE COUTURE & READY-TO-WEAR',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _announcementController,
                          decoration: const InputDecoration(
                            labelText: 'Top Banner Announcement Text',
                            hintText: 'e.g. COMPLIMENTARY WORLDWIDE DELIVERY ON ORDERS OVER \$1,000',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Display Top Announcement Banner'),
                          value: _showAnnouncement,
                          activeThumbColor: colors.accentVariant,
                          onChanged: (v) => setState(() => _showAnnouncement = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            onPressed: _isSavingHeader ? null : _saveHeader,
                            icon: _isSavingHeader
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check, size: 18),
                            label: const Text('SAVE BRAND HEADER'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Navigation Menu Tabs
                Card(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tab_outlined, color: colors.accentVariant),
                                const SizedBox(width: 12),
                                Text(
                                  'NAVIGATION TABS & STOREFRONT LINKS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.0,
                                    color: colors.text,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accentVariant,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showAddEditDialog(),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('ADD TAB'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add, edit, reorder, and control visibility for navigation tabs across the desktop header and mobile drawer.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        if (_navItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text('No navigation tabs configured.')),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _navItems.length,
                            // ignore: deprecated_member_use
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _navItems.removeAt(oldIndex);
                                _navItems.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = _navItems[index];
                              return Container(
                                key: ValueKey(item.id),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant,
                                  border: Border.all(color: colors.border),
                                ),
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.drag_indicator, color: colors.textMuted),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: colors.accentVariant.withValues(alpha: 0.2),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(fontSize: 11, color: colors.text, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.isVisible ? colors.text : colors.textMuted,
                                      decoration: item.isVisible ? null : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.path + (item.isExternal ? ' (External)' : ''),
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          item.isVisible ? Icons.visibility : Icons.visibility_off,
                                          color: item.isVisible ? colors.accentVariant : colors.textMuted,
                                        ),
                                        tooltip: item.isVisible ? 'Visible' : 'Hidden',
                                        onPressed: () {
                                          setState(() {
                                            _navItems[index] = item.copyWith(isVisible: !item.isVisible);
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        tooltip: 'Edit Tab',
                                        onPressed: () => _showAddEditDialog(item: item, index: index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                        tooltip: 'Delete Tab',
                                        onPressed: () {
                                          setState(() => _navItems.removeAt(index));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            onPressed: _isSavingNav ? null : _saveNavMenu,
                            icon: _isSavingNav
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check, size: 18),
                            label: const Text('PUBLISH NAVIGATION MENU'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
