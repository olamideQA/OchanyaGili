import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/footer_config.dart';

class Footer extends ConsumerWidget {
  const Footer({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final isMobile = MediaQuery.of(context).size.width < 900;

    final footerConfigAsync = ref.watch(footerConfigProvider);
    final brandHeaderAsync = ref.watch(brandHeaderProvider);

    final brandName = brandHeaderAsync.value?.brandName ?? 'OCHANYA GILI';
    final config = footerConfigAsync.value ?? const FooterConfig(
      tagline: 'Sartorial Sovereignty. Contemporary African Couture crafted with architectural poise.',
      address: 'Victoria Island, Lagos, Nigeria',
      copyright: '© 2026 Ochanya Gili Atelier. All rights reserved.',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/ochanyagili',
        whatsapp: 'https://wa.me/2348000000000',
        twitter: 'https://x.com/ochanyagili',
      ),
      columns: [
        FooterColumn(
          title: 'Collections',
          links: [
            FooterLink(title: 'Benue Regalia', url: '/collections'),
            FooterLink(title: 'Idoma Royal Silk', url: '/collections'),
            FooterLink(title: 'Lookbook Archive', url: '/lookbook'),
          ],
        ),
        FooterColumn(
          title: 'Atelier Concierge',
          links: [
            FooterLink(title: 'Create Your Look', url: '/create-your-look'),
            FooterLink(title: 'Book Private Fitting', url: '/account/appointments/book'),
            FooterLink(title: 'Client Directory', url: '/about'),
          ],
        ),
        FooterColumn(
          title: 'The Maison',
          links: [
            FooterLink(title: 'Our Heritage', url: '/about'),
            FooterLink(title: 'Editorial Journal', url: '/journal'),
            FooterLink(title: 'Private Consultations', url: '/contact'),
          ],
        ),
      ],
    );

    return Container(
      color: colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: 40.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BrandBlock(
                      brandName: brandName,
                      tagline: config.tagline,
                      address: config.address,
                      socialLinks: config.socialLinks,
                      colors: colors,
                      onLaunch: _launch,
                    ),
                    const SizedBox(height: 32),
                    for (final col in config.columns) ...[
                      _LinkColumn(column: col, colors: colors, onLaunch: _launch),
                      const SizedBox(height: 24),
                    ],
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _BrandBlock(
                        brandName: brandName,
                        tagline: config.tagline,
                        address: config.address,
                        socialLinks: config.socialLinks,
                        colors: colors,
                        onLaunch: _launch,
                      ),
                    ),
                    const SizedBox(width: 48),
                    for (final col in config.columns)
                      Expanded(
                        flex: 1,
                        child: _LinkColumn(column: col, colors: colors, onLaunch: _launch),
                      ),
                  ],
                ),
              const SizedBox(height: 36),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      config.copyright.isNotEmpty
                          ? config.copyright
                          : '© ${DateTime.now().year} $brandName. All rights reserved.',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                    Text(
                      'Haute Couture & Ready-To-Wear',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}

class _BrandBlock extends StatelessWidget {
  final String brandName;
  final String tagline;
  final String address;
  final SocialLinks socialLinks;
  final AppColorTokens colors;
  final Function(String) onLaunch;

  const _BrandBlock({
    required this.brandName,
    required this.tagline,
    required this.address,
    required this.socialLinks,
    required this.colors,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          brandName,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            color: colors.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 18,
          ),
        ),
        if (tagline.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            tagline,
            style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.5),
          ),
        ],
        if (address.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: colors.accentVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  address,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (socialLinks.instagram.isNotEmpty)
              _SocialIconButton(
                icon: Icons.camera_alt_outlined,
                tooltip: 'Instagram',
                colors: colors,
                onTap: () => onLaunch(socialLinks.instagram),
              ),
            if (socialLinks.whatsapp.isNotEmpty)
              _SocialIconButton(
                icon: Icons.chat_outlined,
                tooltip: 'WhatsApp Concierge',
                colors: colors,
                onTap: () => onLaunch(socialLinks.whatsapp),
              ),
            if (socialLinks.twitter.isNotEmpty)
              _SocialIconButton(
                icon: Icons.alternate_email,
                tooltip: 'X / Twitter',
                colors: colors,
                onTap: () => onLaunch(socialLinks.twitter),
              ),
            if (socialLinks.facebook.isNotEmpty)
              _SocialIconButton(
                icon: Icons.facebook_outlined,
                tooltip: 'Facebook',
                colors: colors,
                onTap: () => onLaunch(socialLinks.facebook),
              ),
          ],
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final AppColorTokens colors;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(icon, size: 18, color: colors.textMuted),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.all(6),
      ),
    );
  }
}

class _LinkColumn extends StatelessWidget {
  final FooterColumn column;
  final AppColorTokens colors;
  final Function(String) onLaunch;

  const _LinkColumn({
    required this.column,
    required this.colors,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          column.title.toUpperCase(),
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        for (final link in column.links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              onTap: () {
                if (link.isExternal || link.url.startsWith('http://') || link.url.startsWith('https://')) {
                  onLaunch(link.url);
                } else {
                  context.go(link.url);
                }
              },
              child: Text(
                link.title,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
