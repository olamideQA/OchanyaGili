import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/account/data/customer_account_repository.dart';
import 'package:ochanya_gili/features/account/domain/models/customer_account_models.dart';

class CustomerAddressesScreen extends ConsumerWidget {
  const CustomerAddressesScreen({super.key});

  void _openAddressDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppColorTokens colors, {
    CustomerAddress? existing,
  }) {
    final labelCtrl = TextEditingController(text: existing?.label ?? 'Home');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final line1Ctrl =
        TextEditingController(text: existing?.addressLine1 ?? '');
    final line2Ctrl =
        TextEditingController(text: existing?.addressLine2 ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Abuja');
    final stateCtrl =
        TextEditingController(text: existing?.state ?? 'FCT');
    final postalCtrl =
        TextEditingController(text: existing?.postalCode ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.instructions ?? '');
    bool isDefault = existing?.isDefault ?? false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              title: Text(
                existing == null ? 'ADD DELIVERY ADDRESS' : 'EDIT ADDRESS',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: colors.primaryText,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                          'Address Label (e.g. Home, Office, Villa)',
                          labelCtrl,
                          colors),
                      const SizedBox(height: 12),
                      _buildTextField('Recipient Full Name', nameCtrl, colors),
                      const SizedBox(height: 12),
                      _buildTextField('Phone Number', phoneCtrl, colors),
                      const SizedBox(height: 12),
                      _buildTextField('Street Address Line 1', line1Ctrl, colors),
                      const SizedBox(height: 12),
                      _buildTextField(
                          'Apartment / Suite / Floor (Optional)',
                          line2Ctrl,
                          colors),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField('City', cityCtrl, colors)),
                          const SizedBox(width: 12),
                          Expanded(
                              child:
                                  _buildTextField('State', stateCtrl, colors)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(
                                  'Postal Code', postalCtrl, colors)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                                'Country',
                                TextEditingController(text: 'Nigeria'),
                                colors,
                                readOnly: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                          'Delivery Instructions (Gate code, concierge)',
                          notesCtrl,
                          colors,
                          maxLines: 2),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isDefault,
                        activeColor: colors.accent,
                        title: Text('Set as default delivery address',
                            style: TextStyle(
                                fontSize: 13, color: colors.primaryText)),
                        onChanged: (val) {
                          setDialogState(() => isDefault = val ?? false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('CANCEL',
                      style: TextStyle(color: colors.secondaryText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              line1Ctrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill in recipient name, phone, and address.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final address = CustomerAddress(
                              id: existing?.id ?? '',
                              profileId: userId,
                              label: labelCtrl.text.trim().isEmpty
                                  ? 'Home'
                                  : labelCtrl.text.trim(),
                              fullName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              addressLine1: line1Ctrl.text.trim(),
                              addressLine2: line2Ctrl.text.trim().isEmpty
                                  ? null
                                  : line2Ctrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              state: stateCtrl.text.trim(),
                              country: 'Nigeria',
                              postalCode: postalCtrl.text.trim().isEmpty
                                  ? null
                                  : postalCtrl.text.trim(),
                              instructions: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                              isDefault: isDefault,
                            );

                            final repo =
                                ref.read(customerAccountRepositoryProvider);
                            await repo.saveAddress(address);

                            if (context.mounted) {
                              Navigator.of(dialogCtx).pop();
                              ref.invalidate(customerAddressesProvider(userId));
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save: $e')),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.onAccent),
                        )
                      : const Text('SAVE ADDRESS'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController ctrl, AppColorTokens colors,
      {bool readOnly = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: colors.secondaryText),
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colors.accent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('Please sign in to manage your delivery addresses.',
                  style: TextStyle(color: colors.primaryText)),
            );
          }

          final addressesAsync = ref.watch(customerAddressesProvider(user.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOGISTICS & COURIER',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: colors.accentVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Delivery Addresses',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openAddressDialog(
                              context, ref, user.id, colors),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('ADD NEW ADDRESS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    addressesAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: colors.primaryText),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading addresses: $e',
                            style: TextStyle(color: colors.error)),
                      ),
                      data: (addresses) {
                        if (addresses.isEmpty) {
                          return _buildEmptyState(context, ref, user.id, colors);
                        }

                        return Column(
                          children: addresses.map((addr) {
                            return _buildAddressCard(
                                context, ref, addr, colors, user.id);
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, String userId, AppColorTokens colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined,
              size: 48, color: colors.secondaryText),
          const SizedBox(height: 16),
          Text(
            'No Saved Addresses',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your preferred shipping address for white-glove courier deliveries.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                _openAddressDialog(context, ref, userId, colors),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            child: const Text(
              'ADD ADDRESS',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    WidgetRef ref,
    CustomerAddress addr,
    AppColorTokens colors,
    String userId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: addr.isDefault ? colors.accentVariant : colors.border,
          width: addr.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    addr.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                  if (addr.isDefault) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      color: colors.accentVariant.withValues(alpha: 0.15),
                      child: Text(
                        'DEFAULT DELIVERY',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                          color: colors.accentVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Address',
                    onPressed: () => _openAddressDialog(
                        context, ref, userId, colors,
                        existing: addr),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: colors.error),
                    tooltip: 'Delete Address',
                    onPressed: () async {
                      final repo = ref.read(customerAccountRepositoryProvider);
                      await repo.deleteAddress(addr.id);
                      ref.invalidate(customerAddressesProvider(userId));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            addr.fullName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            addr.formattedAddress,
            style: TextStyle(fontSize: 13, color: colors.secondaryText),
          ),
          const SizedBox(height: 2),
          Text(
            'Phone: ${addr.phone}',
            style: TextStyle(fontSize: 12, color: colors.secondaryText),
          ),
          if (addr.instructions != null && addr.instructions!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Instructions: ${addr.instructions}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colors.secondaryText,
              ),
            ),
          ],
          if (!addr.isDefault) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final repo = ref.read(customerAccountRepositoryProvider);
                await repo.setDefaultAddress(userId, addr.id);
                ref.invalidate(customerAddressesProvider(userId));
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colors.accentVariant,
                textStyle: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold),
              ),
              child: const Text('MAKE DEFAULT ADDRESS'),
            ),
          ],
        ],
      ),
    );
  }
}
