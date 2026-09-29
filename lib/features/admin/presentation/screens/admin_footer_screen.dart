import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/footer_config.dart';

class AdminFooterScreen extends ConsumerStatefulWidget {
  const AdminFooterScreen({super.key});

  @override
  ConsumerState<AdminFooterScreen> createState() => _AdminFooterScreenState();
}

class _AdminFooterScreenState extends ConsumerState<AdminFooterScreen> {
  final _taglineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _copyrightCtrl = TextEditingController();

  final _instagramCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  List<FooterColumn> _columns = [];
  bool _isSaving = false;
  bool _configLoaded = false;

  @override
  void dispose() {
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _copyrightCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    _twitterCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  void _initFromConfig(FooterConfig config) {
    if (!_configLoaded) {
      _taglineCtrl.text = config.tagline;
      _addressCtrl.text = config.address;
      _copyrightCtrl.text = config.copyright;

      _instagramCtrl.text = config.socialLinks.instagram;
      _whatsappCtrl.text = config.socialLinks.whatsapp;
      _twitterCtrl.text = config.socialLinks.twitter;
      _facebookCtrl.text = config.socialLinks.facebook;

      _columns = List.from(config.columns);
      _configLoaded = true;
    }
  }

  Future<void> _publishFooter() async {
    setState(() => _isSaving = true);
    try {
      final config = FooterConfig(
        tagline: _taglineCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        copyright: _copyrightCtrl.text.trim(),
        socialLinks: SocialLinks(
          instagram: _instagramCtrl.text.trim(),
          whatsapp: _whatsappCtrl.text.trim(),
          twitter: _twitterCtrl.text.trim(),
          facebook: _facebookCtrl.text.trim(),
        ),
        columns: _columns,
      );

      await ref.read(cmsRepositoryProvider).saveFooterConfig(config);
      ref.invalidate(footerConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Footer published! Storefront links updated live.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish footer: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddColumnDialog() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<AppColorTokens>()!;
        return AlertDialog(
          title: const Text('Add Footer Column', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Column Title',
              hintText: 'e.g. Collections, Customer Care, The Maison',
              border: OutlineInputBorder(),
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
                if (title.isNotEmpty) {
                  setState(() {
                    _columns.add(FooterColumn(title: title, links: []));
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add Column'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLinkDialog(int columnIndex) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: '/');
    bool isExternal = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = Theme.of(ctx).extension<AppColorTokens>()!;
          return AlertDialog(
            title: Text(
              'Add Link to "${_columns[columnIndex].title}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Link Title',
                    hintText: 'e.g. Benue Regalia, Book Fitting, Care Guide',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL or Route',
                    hintText: 'e.g. /collections, /p/heritage, https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('External Link'),
                  value: isExternal,
                  activeThumbColor: colors.accentVariant,
                  onChanged: (v) => setDialogState(() => isExternal = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
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
                  final url = urlCtrl.text.trim();
                  if (title.isNotEmpty && url.isNotEmpty) {
                    setState(() {
                      final updatedLinks = List<FooterLink>.from(_columns[columnIndex].links)
                        ..add(FooterLink(title: title, url: url, isExternal: isExternal));
                      _columns[columnIndex] = FooterColumn(
                        title: _columns[columnIndex].title,
                        links: updatedLinks,
                      );
                    });
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Add Link'),
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
    final footerAsync = ref.watch(footerConfigProvider);
    footerAsync.whenData((cfg) => _initFromConfig(cfg));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'STOREFRONT FOOTER & SOCIALS STUDIO',
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
                // Section 1: Maison Info & Legal
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
                            Icon(Icons.business_outlined, color: colors.accentVariant),
                            const SizedBox(width: 12),
                            Text(
                              'MAISON PROFILE & LEGAL',
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
                          'Configure the brand manifesto text, physical atelier address, and copyright text displayed at the base of every page.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _taglineCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Maison Tagline / Manifesto',
                            hintText: 'Sartorial Sovereignty. Contemporary African Couture...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Physical Atelier Address',
                            hintText: 'Victoria Island, Lagos, Nigeria',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _copyrightCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Copyright Notice',
                            hintText: '© 2026 Ochanya Gili Atelier. All rights reserved.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Social Media Handles
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
                            Icon(Icons.share_outlined, color: colors.accentVariant),
                            const SizedBox(width: 12),
                            Text(
                              'SOCIAL MEDIA & CONCIERGE CHANNELS',
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
                          'Direct clients to your Instagram portfolio, WhatsApp concierge, and social platforms.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _instagramCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Instagram URL',
                            hintText: 'https://instagram.com/ochanyagili',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.camera_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _whatsappCtrl,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Concierge Link / Number',
                            hintText: 'https://wa.me/2348000000000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.chat_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _twitterCtrl,
                          decoration: const InputDecoration(
                            labelText: 'X / Twitter URL',
                            hintText: 'https://x.com/ochanyagili',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _facebookCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Facebook URL',
                            hintText: 'https://facebook.com/ochanyagili',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.facebook_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Footer Navigation Columns & Custom Links
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
                                Icon(Icons.view_column_outlined, color: colors.accentVariant),
                                const SizedBox(width: 12),
                                Text(
                                  'FOOTER NAVIGATION COLUMNS & LINKS',
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
                              onPressed: _showAddColumnDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('ADD COLUMN'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Organize footer links into distinct columns. Add custom links to shop collections, policy pages, or custom content.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),

                        for (int colIdx = 0; colIdx < _columns.length; colIdx++) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _columns[colIdx].title.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        fontSize: 14,
                                        color: colors.text,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showAddLinkDialog(colIdx),
                                          icon: const Icon(Icons.add_link, size: 16),
                                          label: const Text('Add Link'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          tooltip: 'Delete Column',
                                          onPressed: () {
                                            setState(() => _columns.removeAt(colIdx));
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(),
                                if (_columns[colIdx].links.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'No links in this column. Click "Add Link" above.',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  )
                                else
                                  for (int linkIdx = 0; linkIdx < _columns[colIdx].links.length; linkIdx++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.link, size: 14, color: colors.accentVariant),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_columns[colIdx].links[linkIdx].title}  →  ${_columns[colIdx].links[linkIdx].url}',
                                              style: TextStyle(fontSize: 13, color: colors.text),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Colors.black45),
                                            tooltip: 'Remove Link',
                                            onPressed: () {
                                              setState(() {
                                                final updated = List<FooterLink>.from(_columns[colIdx].links)
                                                  ..removeAt(linkIdx);
                                                _columns[colIdx] = FooterColumn(
                                                  title: _columns[colIdx].title,
                                                  links: updated,
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _publishFooter,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text(
                      'PUBLISH FOOTER & SOCIALS',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
