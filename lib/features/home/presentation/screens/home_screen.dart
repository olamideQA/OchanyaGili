import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/home/presentation/widgets/editorial_hero.dart';
import 'package:ochanya_gili/features/home/presentation/widgets/editorial_collection_section.dart';
import 'package:ochanya_gili/features/home/presentation/widgets/atelier_statement_section.dart';
import 'package:ochanya_gili/features/home/presentation/widgets/home_journal_preview.dart';
import 'package:ochanya_gili/features/shop/data/products_repository.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final heroSlidesAsync = ref.watch(heroSlidesProvider);
    final editorialBlockAsync = ref.watch(editorialBlockProvider);
    final journalPostsAsync = ref.watch(journalPostsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Campaign Hero (sleek editorial height)
          heroSlidesAsync.when(
            data: (slides) => EditorialHero(slides: slides),
            loading: () => SizedBox(
              height: (MediaQuery.of(context).size.height * 0.52).clamp(380.0, 470.0),
              child: Center(
                child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5),
              ),
            ),
            error: (err, stack) => SizedBox(
              height: 380,
              child: Center(
                child: Text('OCHANYA GILI', style: TextStyle(color: colors.primaryText, fontSize: 32, letterSpacing: 4)),
              ),
            ),
          ),

          // 2. The Atelier Manifesto Statement
          const AtelierStatementSection(),

          // 3. "The Collection" Editorial Block & Horizontal Gallery
          editorialBlockAsync.when(
            data: (block) => EditorialCollectionSection(block: block),
            loading: () => const SizedBox(height: 200),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // 4. Reviews strip (Ozinna-style social proof)
          const _ReviewsStrip(),

          // 5. Explore your style (Ozinna-style product grid)
          const _ExploreStyleSection(),

          // 6. Dispatches from The Journal
          journalPostsAsync.when(
            data: (posts) => HomeJournalPreview(posts: posts),
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // 7. Newsletter capture (Ozinna-style list building)
          const _NewsletterSection(),

          // Footer
          const Footer(),
        ],
      ),
    );
  }
}

class _NewsletterSection extends StatefulWidget {
  const _NewsletterSection();

  @override
  State<_NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<_NewsletterSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppColorTokens colors) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('og_newsletter_v1') ?? <String>[];
      raw.add('${_nameController.text.trim()}|${_emailController.text.trim()}|${DateTime.now().toIso8601String()}');
      await prefs.setStringList('og_newsletter_v1', raw);
    } catch (_) {}
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 64, vertical: isMobile ? 48 : 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _done
              ? Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: colors.success),
                    const SizedBox(height: 12),
                    Text('Thank you for joining our mailing list!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, color: colors.primaryText)),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text('PRIVATE LIST',
                          style: TextStyle(color: colors.accentVariant, fontSize: 12, letterSpacing: 3.0, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text('First to know: new drops & private fittings',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Playfair Display', fontSize: isMobile ? 24 : 30, color: colors.primaryText)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'First name',
                          labelStyle: TextStyle(color: colors.secondaryText),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primaryText)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email address',
                          labelStyle: TextStyle(color: colors.secondaryText),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primaryText)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _submit(colors),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: const Text('SIGN UP', style: TextStyle(letterSpacing: 2.0, fontSize: 13, fontWeight: FontWeight.bold)),
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

class _ReviewsStrip extends StatelessWidget {
  const _ReviewsStrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final isMobile = MediaQuery.of(context).size.width < 768;
    // DEMO-SEED: 3 pitch client quotes. Replace names/quotes with real
    // client testimonials before contract pitch. Strip with DemoConfig.
    const reviews = [
      ['Adaeze O.', 'Bridal, Abuja', 'The fitting felt like architecture — every seam landed exactly where it should. I have never been photographed so much.'],
      ['Funke A.', 'Private client, Lagos', 'From sketch to final fitting in three weeks. The peplum holds its shape from morning to midnight.'],
      ['Zainab I.', 'Red carpet, London', 'Wore Ochanya Gili to a premiere and three stylists asked for the atelier number. Worth every naira.'],
    ];
    return Container(
      width: double.infinity,
      color: colors.surfaceVariant,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 64, vertical: isMobile ? 48 : 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('WORN & LOVED',
                  style: TextStyle(color: colors.accentVariant, fontSize: 12, letterSpacing: 3.0, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('4.9★ from 200+ private fittings',
                  style: TextStyle(fontFamily: 'Playfair Display', fontSize: isMobile ? 22 : 28, color: colors.primaryText)),
              const SizedBox(height: 28),
              if (isMobile)
                Column(
                  children: [for (final r in reviews) _ReviewCard(review: r, colors: colors)],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final r in reviews) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: _ReviewCard(review: r, colors: colors)))],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final List<String> review;
  final AppColorTokens colors;
  const _ReviewCard({required this.review, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [for (var i = 0; i < 5; i++) Icon(Icons.star, size: 16, color: colors.accentVariant)]),
          const SizedBox(height: 12),
          Text('“${review[2]}”',
              style: TextStyle(fontFamily: 'Playfair Display', fontStyle: FontStyle.italic, fontSize: 15, height: 1.6, color: colors.primaryText)),
          const SizedBox(height: 16),
          Text(review[0], style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 13)),
          Text(review[1], style: TextStyle(color: colors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ExploreStyleSection extends ConsumerWidget {
  const _ExploreStyleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final productsAsync = ref.watch(allPublishedProductsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        final items = products.take(4).toList();
        return Container(
          width: double.infinity,
          color: colors.surface,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 64, vertical: isMobile ? 48 : 72),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                children: [
                  Text('THE ATELIER EDIT',
                      style: TextStyle(fontSize: isMobile ? 24 : 34, letterSpacing: 2.5, color: colors.primaryText)),
                  const SizedBox(height: 8),
                  Text('Signature gowns, bespoke bridal couture, and handwoven silhouettes.',
                      style: TextStyle(color: colors.textMuted, fontSize: 14)),
                  const SizedBox(height: 32),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 32,
                      childAspectRatio: isMobile ? 0.65 : 0.74,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final hasSale = p.compareAtPrice != null && p.compareAtPrice! > p.basePrice;
                      return InkWell(
                        onTap: () => context.go('/shop/${p.slug}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRect(
                                    child: CachedNetworkImage(
                                      imageUrl: p.primaryImageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: colors.surfaceVariant),
                                      errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                                    ),
                                  ),
                                  if (hasSale)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        color: colors.accentVariant,
                                        child: const Text('SALE',
                                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(p.name.toUpperCase(),
                                style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: colors.primaryText, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(currency.format(p.basePrice),
                                    style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w600)),
                                if (hasSale) ...[
                                  const SizedBox(width: 8),
                                  Text(currency.format(p.compareAtPrice!),
                                      style: TextStyle(color: colors.textMuted, decoration: TextDecoration.lineThrough, fontSize: 13)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
