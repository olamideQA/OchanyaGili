import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final contactAsync = ref.watch(contactDetailsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return contactAsync.when(
      data: (details) => SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 64.0,
                vertical: isMobile ? 48.0 : 80.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    'CONCIERGE & PRIVATE APPOINTMENTS',
                    style: TextStyle(
                      color: colors.accentVariant,
                      fontSize: 12,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect with the Atelier',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: isMobile ? 32 : 44,
                      color: colors.primaryText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Studio details
                        Expanded(
                          flex: 5,
                          child: _buildDetailsColumn(details, colors),
                        ),
                        const SizedBox(width: 80),
                        // Right: Inquiry Form
                        Expanded(
                          flex: 6,
                          child: _buildForm(colors),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailsColumn(details, colors),
                        const SizedBox(height: 48),
                        Divider(color: colors.border),
                        const SizedBox(height: 48),
                        _buildForm(colors),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const Footer(),
      ],
    ),
  ),
  loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5)),
  error: (err, stack) => Center(child: Text('Failed to load contact info', style: TextStyle(color: colors.error))),
);
  }

  Widget _buildDetailsColumn(ContactDetails details, AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailItem(
          title: 'STUDIO LOCATION',
          value: details.address,
          colors: colors,
        ),
        const SizedBox(height: 32),
        _DetailItem(
          title: 'CONCIERGE INQUIRIES',
          value: details.conciergeEmail,
          colors: colors,
        ),
        const SizedBox(height: 32),
        _DetailItem(
          title: 'TELEPHONE & WHATSAPP',
          value: details.studioPhone,
          colors: colors,
        ),
        const SizedBox(height: 32),
        _DetailItem(
          title: 'SALON HOURS',
          value: details.openingHours,
          colors: colors,
        ),
        const SizedBox(height: 32),
        _DetailItem(
          title: 'DIGITAL SALON',
          value: details.instagram,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildForm(AppColorTokens colors) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(40.0),
        color: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: colors.success),
            const SizedBox(height: 20),
            Text(
              'Inquiry Received',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 26,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our atelier concierge will contact you within 24 hours to schedule your consultation.',
              style: TextStyle(color: colors.secondaryText, fontSize: 15, height: 1.6),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(36.0),
      color: colors.surface,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEND AN INQUIRY',
              style: TextStyle(
                color: colors.primaryText,
                letterSpacing: 2.0,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                labelStyle: TextStyle(color: colors.secondaryText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primaryText)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address *',
                labelStyle: TextStyle(color: colors.secondaryText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primaryText)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telephone (optional)',
                labelStyle: TextStyle(color: colors.secondaryText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primaryText)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message / Occasion Details *',
                labelStyle: TextStyle(color: colors.secondaryText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.primaryText)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('SUBMIT INQUIRY', style: TextStyle(letterSpacing: 2.0, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String title;
  final String value;
  final AppColorTokens colors;

  const _DetailItem({
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
