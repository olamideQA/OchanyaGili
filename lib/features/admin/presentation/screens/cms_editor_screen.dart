import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';

class CmsEditorScreen extends ConsumerStatefulWidget {
  const CmsEditorScreen({super.key});

  @override
  ConsumerState<CmsEditorScreen> createState() => _CmsEditorScreenState();
}

class _CmsEditorScreenState extends ConsumerState<CmsEditorScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Hero Controllers
  final _heroTitleController = TextEditingController();
  final _heroSubtitleController = TextEditingController();
  final _heroCtaTextController = TextEditingController();
  final _heroCtaLinkController = TextEditingController();
  final _heroDesktopImgController = TextEditingController();
  final _heroMobileImgController = TextEditingController();

  // Editorial Controllers
  final _editorialHeadlineController = TextEditingController();
  final _editorialSubheadlineController = TextEditingController();
  final _editorialBodyController = TextEditingController();
  final _editorialImgController = TextEditingController();
  final _editorialCtaTextController = TextEditingController();
  final _editorialCtaLinkController = TextEditingController();

  // About Controllers
  final _aboutTitleController = TextEditingController();
  final _aboutPhilosophyController = TextEditingController();
  final _aboutCraftsmanshipController = TextEditingController();
  final _aboutBioController = TextEditingController();
  final _aboutAddressController = TextEditingController();
  final _aboutHeroImgController = TextEditingController();

  // Contact Controllers
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactAddressController = TextEditingController();
  final _contactHoursController = TextEditingController();
  final _contactInstagramController = TextEditingController();

  bool _isSaving = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialValues();
  }

  Future<void> _loadInitialValues() async {
    final repo = ref.read(cmsRepositoryProvider);

    // Hero
    final slides = await repo.getHeroSlides();
    if (slides.isNotEmpty) {
      final s = slides.first;
      _heroTitleController.text = s.title;
      _heroSubtitleController.text = s.subtitle;
      _heroCtaTextController.text = s.ctaText;
      _heroCtaLinkController.text = s.ctaLink;
      _heroDesktopImgController.text = s.desktopImageUrl;
      _heroMobileImgController.text = s.mobileImageUrl;
    }

    // Editorial
    final block = await repo.getEditorialBlock();
    _editorialHeadlineController.text = block.headline;
    _editorialSubheadlineController.text = block.subheadline;
    _editorialBodyController.text = block.body;
    _editorialImgController.text = block.imageUrl;
    _editorialCtaTextController.text = block.ctaText;
    _editorialCtaLinkController.text = block.ctaLink;

    // About
    final about = await repo.getAboutContent();
    _aboutTitleController.text = about.title;
    _aboutPhilosophyController.text = about.philosophy;
    _aboutCraftsmanshipController.text = about.craftsmanship;
    _aboutBioController.text = about.designerBio;
    _aboutAddressController.text = about.studioAddress;
    _aboutHeroImgController.text = about.heroImageUrl;

    // Contact
    final contact = await repo.getContactDetails();
    _contactEmailController.text = contact.conciergeEmail;
    _contactPhoneController.text = contact.studioPhone;
    _contactAddressController.text = contact.address;
    _contactHoursController.text = contact.openingHours;
    _contactInstagramController.text = contact.instagram;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _heroCtaTextController.dispose();
    _heroCtaLinkController.dispose();
    _heroDesktopImgController.dispose();
    _heroMobileImgController.dispose();

    _editorialHeadlineController.dispose();
    _editorialSubheadlineController.dispose();
    _editorialBodyController.dispose();
    _editorialImgController.dispose();
    _editorialCtaTextController.dispose();
    _editorialCtaLinkController.dispose();

    _aboutTitleController.dispose();
    _aboutPhilosophyController.dispose();
    _aboutCraftsmanshipController.dispose();
    _aboutBioController.dispose();
    _aboutAddressController.dispose();
    _aboutHeroImgController.dispose();

    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactAddressController.dispose();
    _contactHoursController.dispose();
    _contactInstagramController.dispose();
    super.dispose();
  }

  Future<void> _saveHero() async {
    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    try {
      final repo = ref.read(cmsRepositoryProvider);
      final updatedSlide = HeroSlide(
        id: 'primary-campaign-slide',
        title: _heroTitleController.text.trim(),
        subtitle: _heroSubtitleController.text.trim(),
        ctaText: _heroCtaTextController.text.trim(),
        ctaLink: _heroCtaLinkController.text.trim(),
        desktopImageUrl: _heroDesktopImgController.text.trim(),
        mobileImageUrl: _heroMobileImgController.text.trim(),
        sortOrder: 0,
      );

      await repo.updateHeroSlides([updatedSlide]);
      ref.invalidate(heroSlidesProvider);

      setState(() => _feedbackMessage = 'Hero campaign updated live on public storefront!');
    } catch (e) {
      setState(() => _feedbackMessage = 'Error updating hero: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveEditorial() async {
    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    try {
      final repo = ref.read(cmsRepositoryProvider);
      final updatedBlock = EditorialBlock(
        headline: _editorialHeadlineController.text.trim(),
        subheadline: _editorialSubheadlineController.text.trim(),
        body: _editorialBodyController.text.trim(),
        imageUrl: _editorialImgController.text.trim(),
        ctaText: _editorialCtaTextController.text.trim(),
        ctaLink: _editorialCtaLinkController.text.trim(),
      );

      await repo.updateEditorialBlock(updatedBlock);
      ref.invalidate(editorialBlockProvider);

      setState(() => _feedbackMessage = 'Featured editorial block updated live on public storefront!');
    } catch (e) {
      setState(() => _feedbackMessage = 'Error updating editorial: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAbout() async {
    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    try {
      final repo = ref.read(cmsRepositoryProvider);
      final updatedAbout = AboutContent(
        title: _aboutTitleController.text.trim(),
        philosophy: _aboutPhilosophyController.text.trim(),
        craftsmanship: _aboutCraftsmanshipController.text.trim(),
        designerBio: _aboutBioController.text.trim(),
        studioAddress: _aboutAddressController.text.trim(),
        heroImageUrl: _aboutHeroImgController.text.trim(),
      );

      await repo.updateAboutContent(updatedAbout);
      ref.invalidate(aboutContentProvider);

      setState(() => _feedbackMessage = 'About & Philosophy section updated live on public storefront!');
    } catch (e) {
      setState(() => _feedbackMessage = 'Error updating about content: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveContact() async {
    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    try {
      final repo = ref.read(cmsRepositoryProvider);
      final updatedContact = ContactDetails(
        conciergeEmail: _contactEmailController.text.trim(),
        studioPhone: _contactPhoneController.text.trim(),
        address: _contactAddressController.text.trim(),
        openingHours: _contactHoursController.text.trim(),
        instagram: _contactInstagramController.text.trim(),
      );

      await repo.updateContactDetails(updatedContact);
      ref.invalidate(contactDetailsProvider);

      setState(() => _feedbackMessage = 'Concierge & Studio details updated live on public storefront!');
    } catch (e) {
      setState(() => _feedbackMessage = 'Error updating contact details: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'CMS & Editorial Management',
          style: TextStyle(
            color: colors.primaryText,
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primaryText,
          indicatorColor: colors.accentVariant,
          tabs: const [
            Tab(text: 'Hero Campaign'),
            Tab(text: 'Featured Editorial'),
            Tab(text: 'About & Philosophy'),
            Tab(text: 'Concierge & Contact'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            if (_feedbackMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _feedbackMessage!.startsWith('Error')
                      ? colors.error.withValues(alpha: 0.1)
                      : colors.success.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _feedbackMessage!.startsWith('Error') ? colors.error : colors.success,
                  ),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: TextStyle(
                    color: _feedbackMessage!.startsWith('Error') ? colors.error : colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHeroEditor(colors),
                  _buildEditorialEditor(colors),
                  _buildAboutEditor(colors),
                  _buildContactEditor(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroEditor(AppColorTokens colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Headline Title', _heroTitleController, colors),
          _field('Subtitle / Tagline', _heroSubtitleController, colors),
          _field('CTA Button Text', _heroCtaTextController, colors),
          _field('CTA Route Link', _heroCtaLinkController, colors),
          _field('Desktop Artwork Image URL', _heroDesktopImgController, colors),
          _field('Mobile Artwork Image URL', _heroMobileImgController, colors),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveHero,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('PUBLISH HERO LIVE', style: TextStyle(letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialEditor(AppColorTokens colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Subheadline / Season (e.g. AUTUMN / WINTER 2026)', _editorialSubheadlineController, colors),
          _field('Main Headline (e.g. THE RESORT COLLECTION)', _editorialHeadlineController, colors),
          _field('Editorial Body Text', _editorialBodyController, colors, maxLines: 4),
          _field('Large Artwork Image URL', _editorialImgController, colors),
          _field('CTA Button Text', _editorialCtaTextController, colors),
          _field('CTA Route Link', _editorialCtaLinkController, colors),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveEditorial,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('PUBLISH EDITORIAL BLOCK LIVE', style: TextStyle(letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutEditor(AppColorTokens colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('House Title', _aboutTitleController, colors),
          _field('Atelier Philosophy', _aboutPhilosophyController, colors, maxLines: 3),
          _field('Anatomy of Craftsmanship', _aboutCraftsmanshipController, colors, maxLines: 3),
          _field('Designer Biography', _aboutBioController, colors, maxLines: 2),
          _field('Studio Address', _aboutAddressController, colors),
          _field('Hero Campaign Image URL', _aboutHeroImgController, colors),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveAbout,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('PUBLISH ABOUT CONTENT LIVE', style: TextStyle(letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactEditor(AppColorTokens colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Concierge Email', _contactEmailController, colors),
          _field('Studio Phone / WhatsApp', _contactPhoneController, colors),
          _field('Physical Address', _contactAddressController, colors),
          _field('Salon Hours', _contactHoursController, colors),
          _field('Digital Salon / Instagram Handle', _contactInstagramController, colors),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveContact,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('PUBLISH CONCIERGE DETAILS LIVE', style: TextStyle(letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, AppColorTokens colors, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.secondaryText),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
