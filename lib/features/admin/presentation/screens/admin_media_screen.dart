import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/media/data/media_service.dart';
import 'package:ochanya_gili/features/media/domain/models/media_asset.dart';

class AdminMediaScreen extends ConsumerStatefulWidget {
  const AdminMediaScreen({super.key});

  @override
  ConsumerState<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends ConsumerState<AdminMediaScreen> {
  String _selectedBucket = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _buckets = [
    'all',
    'products',
    'collections',
    'lookbook',
    'journal',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUploadDialog(BuildContext context, AppColorTokens colors) {
    showDialog(
      context: context,
      builder: (ctx) => _UploadAssetDialog(
        defaultBucket: _selectedBucket == 'all' ? 'products' : _selectedBucket,
        onUploaded: () {
          ref.invalidate(mediaAssetsProvider);
        },
      ),
    );
  }

  void _openEditDialog(BuildContext context, MediaAsset asset, AppColorTokens colors) {
    final titleController = TextEditingController(text: asset.title);
    final altTextController = TextEditingController(text: asset.altText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Edit Asset Metadata',
          style: TextStyle(
            color: colors.primaryText,
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Asset Title',
                labelStyle: TextStyle(color: colors.secondaryText),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: altTextController,
              decoration: InputDecoration(
                labelText: 'Accessible Alt Text (SEO)',
                labelStyle: TextStyle(color: colors.secondaryText),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: TextStyle(color: colors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
            ),
            onPressed: () async {
              await ref.read(mediaServiceProvider).updateAssetMetadata(
                    id: asset.id,
                    title: titleController.text.trim(),
                    altText: altTextController.text.trim(),
                  );
              ref.invalidate(mediaAssetsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('SAVE METADATA'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MediaAsset asset, AppColorTokens colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Delete Media Asset',
          style: TextStyle(
            color: colors.primaryText,
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${asset.filename}" from the ${asset.bucket} repository?',
          style: TextStyle(color: colors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: TextStyle(color: colors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(mediaServiceProvider).deleteAsset(asset);
              ref.invalidate(mediaAssetsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('DELETE ASSET'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final mediaAsync = ref.watch(mediaAssetsProvider(_selectedBucket));

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
                      'MEDIA & EDITORIAL PIPELINE',
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
                      'High-resolution garment imagery, CDN optimization, responsive variants, and alt tags',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(mediaAssetsProvider),
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
                      onPressed: () => _openUploadDialog(context, colors),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text('UPLOAD ASSET'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onAccent,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls: Buckets & Search Filter
            Row(
              children: [
                // Bucket Filter Tabs
                Wrap(
                  spacing: 8,
                  children: _buckets.map((b) {
                    final isSelected = _selectedBucket == b;
                    return ChoiceChip(
                      label: Text(
                        b.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colors.onAccent : colors.primaryText,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colors.accent,
                      backgroundColor: colors.surface,
                      side: BorderSide(color: isSelected ? colors.accent : colors.border),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedBucket = b);
                        }
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                // Search Input
                SizedBox(
                  width: 260,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search filename or alt...',
                      hintStyle: TextStyle(fontSize: 12, color: colors.secondaryText),
                      prefixIcon: Icon(Icons.search, size: 18, color: colors.secondaryText),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      filled: true,
                      fillColor: colors.surface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Media Grid
            mediaAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading media: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (items) {
                final filtered = items.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery;
                  return item.filename.toLowerCase().contains(q) ||
                      item.title.toLowerCase().contains(q) ||
                      item.altText.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
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
                          Icon(Icons.perm_media_outlined, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            'No media assets found in this bucket.',
                            style: TextStyle(color: colors.secondaryText, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _openUploadDialog(context, colors),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accent,
                              foregroundColor: colors.onAccent,
                            ),
                            child: const Text('UPLOAD FIRST ASSET'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1000;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.76,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image preview
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      color: colors.surfaceVariant,
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Image.network(
                                        item.url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(Icons.broken_image_outlined, color: colors.secondaryText),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        color: Colors.black87,
                                        child: Text(
                                          item.bucket.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (item.responsiveUrls.isNotEmpty)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          color: colors.accentVariant,
                                          child: const Text(
                                            'RESPONSIVE OPTIMIZED',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Metadata & Actions
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title.isNotEmpty ? item.title : item.filename,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: colors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.altText.isNotEmpty ? 'Alt: ${item.altText}' : 'No alt text',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: colors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.formattedSize,
                                      style: TextStyle(fontSize: 10, color: colors.secondaryText),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Copy CDN URL
                                        IconButton(
                                          tooltip: 'Copy CDN URL',
                                          icon: Icon(Icons.copy, size: 16, color: colors.primaryText),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: item.url));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Asset CDN URL copied to clipboard')),
                                            );
                                          },
                                        ),
                                        // Edit Metadata
                                        IconButton(
                                          tooltip: 'Edit Metadata (Alt / Title)',
                                          icon: Icon(Icons.edit_outlined, size: 16, color: colors.primaryText),
                                          onPressed: () => _openEditDialog(context, item, colors),
                                        ),
                                        // Move Reorder Up
                                        IconButton(
                                          tooltip: 'Move Up in Atelier Sequence',
                                          icon: Icon(Icons.arrow_upward, size: 16, color: colors.secondaryText),
                                          onPressed: index > 0
                                              ? () async {
                                                  final reorderedIds = filtered.map((e) => e.id).toList();
                                                  final prev = reorderedIds[index - 1];
                                                  reorderedIds[index - 1] = reorderedIds[index];
                                                  reorderedIds[index] = prev;
                                                  await ref.read(mediaServiceProvider).reorderAssets(reorderedIds);
                                                  ref.invalidate(mediaAssetsProvider);
                                                }
                                              : null,
                                        ),
                                        // Delete
                                        IconButton(
                                          tooltip: 'Delete Asset',
                                          icon: Icon(Icons.delete_outline, size: 16, color: colors.error),
                                          onPressed: () => _confirmDelete(context, item, colors),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadAssetDialog extends ConsumerStatefulWidget {
  final String defaultBucket;
  final VoidCallback onUploaded;

  const _UploadAssetDialog({
    required this.defaultBucket,
    required this.onUploaded,
  });

  @override
  ConsumerState<_UploadAssetDialog> createState() => _UploadAssetDialogState();
}

class _UploadAssetDialogState extends ConsumerState<_UploadAssetDialog> {
  late String _bucket;
  final _titleController = TextEditingController();
  final _altTextController = TextEditingController();
  final List<XFile> _selectedFiles = [];
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bucket = widget.defaultBucket;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _altTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(images);
        if (_titleController.text.isEmpty) {
          _titleController.text = images.first.name.split('.').first;
        }
        if (_altTextController.text.isEmpty) {
          _altTextController.text = images.first.name.split('.').first.replaceAll(RegExp(r'[-_]'), ' ');
        }
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFiles.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one image file.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final mediaService = ref.read(mediaServiceProvider);
      for (final file in _selectedFiles) {
        final bytes = await file.readAsBytes();
        await mediaService.uploadAsset(
          bytes: bytes,
          filename: file.name,
          bucket: _bucket,
          title: _titleController.text.trim(),
          altText: _altTextController.text.trim(),
          mimeType: file.mimeType ?? 'image/jpeg',
        );
      }

      widget.onUploaded();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = 'Upload error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Upload Media Assets',
        style: TextStyle(
          color: colors.primaryText,
          fontFamily: 'Playfair Display',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: colors.error.withValues(alpha: 0.1),
                  child: Text(_errorMessage!, style: TextStyle(color: colors.error, fontSize: 12)),
                ),
              // Bucket selector
              Text('TARGET STORAGE BUCKET', style: TextStyle(fontSize: 11, color: colors.secondaryText)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _bucket,
                items: const [
                  DropdownMenuItem(value: 'products', child: Text('products')),
                  DropdownMenuItem(value: 'collections', child: Text('collections')),
                  DropdownMenuItem(value: 'lookbook', child: Text('lookbook')),
                  DropdownMenuItem(value: 'journal', child: Text('journal')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _bucket = val);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Asset Title / Garment Name',
                  labelStyle: TextStyle(color: colors.secondaryText),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _altTextController,
                decoration: InputDecoration(
                  labelText: 'Accessible Alt Text (for SEO & Screen Readers)',
                  labelStyle: TextStyle(color: colors.secondaryText),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // File Picker Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border, style: BorderStyle.solid),
                  color: colors.surfaceVariant.withValues(alpha: 0.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 36, color: colors.secondaryText),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFiles.isEmpty
                          ? 'No files chosen yet'
                          : '${_selectedFiles.length} file(s) selected for upload',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.file_upload, size: 16),
                      label: const Text('SELECT IMAGES'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.border),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: colors.accentVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automatic Web Optimization: original + responsive CDN tags generated.',
                      style: TextStyle(fontSize: 11, color: colors.secondaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: colors.secondaryText)),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _handleUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
          ),
          child: _isUploading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('START UPLOAD'),
        ),
      ],
    );
  }
}
