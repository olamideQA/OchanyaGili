import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/services/public_content_cache.dart';
import 'package:ochanya_gili/core/utils/performance_tracker.dart';
import 'package:ochanya_gili/features/shop/data/products_repository.dart';
import 'package:ochanya_gili/features/collections/data/collections_repository.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';

class AdminSeoScreen extends ConsumerStatefulWidget {
  const AdminSeoScreen({super.key});

  @override
  ConsumerState<AdminSeoScreen> createState() => _AdminSeoScreenState();
}

class _AdminSeoScreenState extends ConsumerState<AdminSeoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedContentType = 'product'; // 'product', 'collection', 'journal', 'home'
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('SEO, PERFORMANCE & DISCOVERABILITY', style: TextStyle(letterSpacing: 2, fontSize: 16)),
        backgroundColor: colors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primaryText,
          unselectedLabelColor: colors.secondaryText,
          indicatorColor: colors.accentVariant,
          tabs: const [
            Tab(text: 'SERP & SOCIAL PREVIEWS'),
            Tab(text: 'PERFORMANCE TELEMETRY'),
            Tab(text: 'SITEMAP & ROBOTS.TXT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreviewsTab(colors, isMobile),
          _buildTelemetryTab(colors, isMobile),
          _buildSitemapRobotsTab(colors, isMobile),
        ],
      ),
    );
  }

  Widget _buildPreviewsTab(AppColorTokens colors, bool isMobile) {
    final productsAsync = ref.watch(allPublishedProductsProvider);
    final collectionsAsync = ref.watch(publishedCollectionsProvider);
    final journalAsync = ref.watch(journalPostsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTENT METADATA INSPECTOR',
                style: TextStyle(color: colors.accentVariant, letterSpacing: 3, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Simulate search engine snippets, OpenGraph cards and Twitter cards for all public pages.',
                style: TextStyle(color: colors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Filter Controls
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _TypeButton(
                    label: 'PRODUCTS',
                    selected: _selectedContentType == 'product',
                    onTap: () => setState(() {
                      _selectedContentType = 'product';
                      _selectedItemId = null;
                    }),
                    colors: colors,
                  ),
                  _TypeButton(
                    label: 'COLLECTIONS',
                    selected: _selectedContentType == 'collection',
                    onTap: () => setState(() {
                      _selectedContentType = 'collection';
                      _selectedItemId = null;
                    }),
                    colors: colors,
                  ),
                  _TypeButton(
                    label: 'JOURNAL',
                    selected: _selectedContentType == 'journal',
                    onTap: () => setState(() {
                      _selectedContentType = 'journal';
                      _selectedItemId = null;
                    }),
                    colors: colors,
                  ),
                  _TypeButton(
                    label: 'HOMEPAGE',
                    selected: _selectedContentType == 'home',
                    onTap: () => setState(() {
                      _selectedContentType = 'home';
                      _selectedItemId = null;
                    }),
                    colors: colors,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Item Selector
              if (_selectedContentType == 'product')
                productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) return const Text('No products available.');
                    final current = products.firstWhere(
                      (p) => p.id == _selectedItemId,
                      orElse: () => products.first,
                    );
                    _selectedItemId ??= current.id;

                    final metadata = SeoMetadata.product(
                      name: current.name,
                      slug: current.slug,
                      description: current.description ?? current.shortDescription ?? '',
                      price: current.basePrice,
                      imageUrl: current.primaryImageUrl,
                      category: current.categoryName,
                      inStock: current.inStock,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: current.id,
                          decoration: const InputDecoration(labelText: 'Select Product to Preview'),
                          items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                          onChanged: (id) => setState(() => _selectedItemId = id),
                        ),
                        const SizedBox(height: 32),
                        _buildPreviewCards(metadata, colors, isMobile),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),

              if (_selectedContentType == 'collection')
                collectionsAsync.when(
                  data: (collections) {
                    if (collections.isEmpty) return const Text('No collections available.');
                    final current = collections.firstWhere(
                      (c) => c.id == _selectedItemId,
                      orElse: () => collections.first,
                    );
                    _selectedItemId ??= current.id;

                    final metadata = SeoMetadata.collection(
                      title: current.name,
                      slug: current.slug,
                      description: current.description ?? 'Ochanya Gili Couture Collection',
                      season: current.season,
                      imageUrl: current.heroImageUrl,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: current.id,
                          decoration: const InputDecoration(labelText: 'Select Collection to Preview'),
                          items: collections.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (id) => setState(() => _selectedItemId = id),
                        ),
                        const SizedBox(height: 32),
                        _buildPreviewCards(metadata, colors, isMobile),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),

              if (_selectedContentType == 'journal')
                journalAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) return const Text('No journal posts available.');
                    final current = posts.firstWhere(
                      (p) => p.id == _selectedItemId,
                      orElse: () => posts.first,
                    );
                    _selectedItemId ??= current.id;

                    final metadata = SeoMetadata.journalPost(
                      title: current.title,
                      slug: current.slug,
                      excerpt: current.excerpt,
                      publishedDate: current.publishedAt?.toIso8601String(),
                      author: 'Ochanya Gili',
                      imageUrl: current.coverImageUrl,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: current.id,
                          decoration: const InputDecoration(labelText: 'Select Journal Post to Preview'),
                          items: posts.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))).toList(),
                          onChanged: (id) => setState(() => _selectedItemId = id),
                        ),
                        const SizedBox(height: 32),
                        _buildPreviewCards(metadata, colors, isMobile),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),

              if (_selectedContentType == 'home') ...[
                const SizedBox(height: 16),
                _buildPreviewCards(SeoMetadata.home(), colors, isMobile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCards(SeoMetadata metadata, AppColorTokens colors, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Google SERP Preview
        _SectionHeader(title: 'GOOGLE SEARCH RESULTS (SERP)', colors: colors),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.primaryText,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('OG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ochanya Gili', style: TextStyle(color: colors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(metadata.canonicalUrl, style: TextStyle(color: colors.secondaryText, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                metadata.fullTitle,
                style: const TextStyle(
                  color: Color(0xFF1A0DAB),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                metadata.description,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Title: ${metadata.fullTitle.length} chars (Target: 50-60)', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  const SizedBox(width: 16),
                  Text('Description: ${metadata.description.length} chars (Target: 120-160)', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // 2. OpenGraph / WhatsApp / Facebook Preview
        _SectionHeader(title: 'OPENGRAPH SOCIAL CARD (WHATSAPP, FACEBOOK, LINKEDIN)', colors: colors),
        const SizedBox(height: 12),
        Container(
          width: isMobile ? double.infinity : 580,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (metadata.imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 1.91,
                  child: Image.network(
                    metadata.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: colors.surfaceVariant),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OCHANYAGILI.COM', style: TextStyle(color: colors.secondaryText, fontSize: 11, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(metadata.fullTitle, style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(metadata.description, style: TextStyle(color: colors.secondaryText, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // 3. Schema.org JSON-LD
        _SectionHeader(title: 'STRUCTURED DATA (SCHEMA.ORG JSON-LD)', colors: colors),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
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
                  const Text('application/ld+json', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      if (metadata.jsonLdString != null) {
                        Clipboard.setData(ClipboardData(text: metadata.jsonLdString!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON-LD copied to clipboard!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('COPY JSON-LD', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const Divider(),
              Text(
                metadata.jsonLdString ?? 'No JSON-LD configured for this route.',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryTab(AppColorTokens colors, bool isMobile) {
    final tracker = ref.watch(performanceTrackerProvider);
    final cache = ref.watch(publicContentCacheProvider);
    final metrics = tracker.getAllMetrics();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERFORMANCE INSTRUMENTATION & BENCHMARKS',
                style: TextStyle(color: colors.accentVariant, letterSpacing: 3, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Live latency telemetry measuring boot, route transitions, Supabase database queries, and CDN media hydration against production SLA targets.',
                style: TextStyle(color: colors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Cache Hit-Rate Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: colors.accentVariant, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IN-MEMORY PUBLIC CACHE TELEMETRY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: colors.primaryText)),
                          const SizedBox(height: 4),
                          Text('Hit Rate: ${cache.hitRate.toStringAsFixed(1)}% (${cache.cacheHits} Hits / ${cache.cacheMisses} Misses)', style: TextStyle(color: colors.secondaryText, fontSize: 14)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        cache.clear();
                        setState(() {});
                      },
                      child: const Text('PURGE CACHE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Metrics Table
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: metrics.length,
                  separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
                  itemBuilder: (context, index) {
                    final metric = metrics[index];
                    Color statusColor = colors.success;
                    if (metric.isWarning) statusColor = colors.error;
                    if (metric.isAcceptable) statusColor = colors.warning;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(metric.label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.primaryText, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('ID: ${metric.id} • SLA Target: <${metric.targetMs}ms', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${metric.averageMs.toStringAsFixed(0)} ms avg',
                              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15, color: colors.primaryText),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              metric.statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSitemapRobotsTab(AppColorTokens colors, bool isMobile) {
    const robotsTxt = '''# robots.txt for Ochanya Gili Luxury Fashion Atelier
User-agent: *
Allow: /
Allow: /collections
Allow: /collections/*
Allow: /shop
Allow: /shop/*
Allow: /lookbook
Allow: /lookbook/*
Allow: /journal
Allow: /journal/*
Allow: /about
Allow: /contact
Allow: /create-your-look

# Disallow private user accounts and staff dashboards
Disallow: /admin
Disallow: /admin/*
Disallow: /account
Disallow: /account/*
Disallow: /checkout
Disallow: /checkout/*
Disallow: /login
Disallow: /signup
Disallow: /forgot-password

Sitemap: https://ochanyagili.com/sitemap.xml''';

    const sitemapXml = '''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://ochanyagili.com/</loc><priority>1.0</priority></url>
  <url><loc>https://ochanyagili.com/collections</loc><priority>0.9</priority></url>
  <url><loc>https://ochanyagili.com/shop</loc><priority>0.95</priority></url>
  <url><loc>https://ochanyagili.com/lookbook</loc><priority>0.8</priority></url>
  <url><loc>https://ochanyagili.com/journal</loc><priority>0.8</priority></url>
  <url><loc>https://ochanyagili.com/about</loc><priority>0.7</priority></url>
  <url><loc>https://ochanyagili.com/contact</loc><priority>0.7</priority></url>
  <url><loc>https://ochanyagili.com/create-your-look</loc><priority>0.85</priority></url>
</urlset>''';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'ROBOTS.TXT DIRECTIVE', colors: colors),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  border: Border.all(color: colors.border),
                ),
                child: const SelectableText(robotsTxt, style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
              const SizedBox(height: 36),
              _SectionHeader(title: 'SITEMAP.XML DIRECTORY', colors: colors),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  border: Border.all(color: colors.border),
                ),
                child: const SelectableText(sitemapXml, style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColorTokens colors;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primaryText : Colors.transparent,
          border: Border.all(color: selected ? colors.primaryText : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onAccent : colors.primaryText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final AppColorTokens colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(color: colors.accentVariant, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }
}
