import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/custom_atelier/data/custom_atelier_repository.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/admin/presentation/widgets/admin_quote_composer_dialog.dart';

class AdminCustomRequestsScreen extends ConsumerStatefulWidget {
  const AdminCustomRequestsScreen({super.key});

  @override
  ConsumerState<AdminCustomRequestsScreen> createState() =>
      _AdminCustomRequestsScreenState();
}

class _AdminCustomRequestsScreenState
    extends ConsumerState<AdminCustomRequestsScreen> {
  CustomRequestStatus? _statusFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final requestsAsync = ref.watch(adminCustomRequestsProvider((_statusFilter, _searchQuery)));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Bespoke Custom Requests Queue'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter & Search Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: colors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by Request #, client name, email, or occasion...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: colors.border),
                            borderRadius: BorderRadius.zero,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('ALL REQUESTS', null, colors),
                      _filterChip('NEW REQUESTS', CustomRequestStatus.requested, colors),
                      _filterChip('UNDER REVIEW', CustomRequestStatus.underReview, colors),
                      _filterChip('CONSULTATION', CustomRequestStatus.designDiscussion, colors),
                      _filterChip('QUOTE SENT', CustomRequestStatus.quoteSent, colors),
                      _filterChip('PRODUCTION', CustomRequestStatus.production, colors),
                      _filterChip('DELIVERED', CustomRequestStatus.delivered, colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Requests List
          Expanded(
            child: requestsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
              error: (e, _) => Center(child: Text('Error loading requests: $e')),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 16),
                          Text('No custom requests match this filter.', style: TextStyle(color: colors.secondaryText)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _buildAdminRequestCard(context, req, colors);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, CustomRequestStatus? status, AppColorTokens colors) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _statusFilter = status);
        },
        selectedColor: colors.primaryText,
        labelStyle: TextStyle(
          color: isSelected ? colors.onAccent : colors.primaryText,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: colors.surfaceVariant,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Widget _buildAdminRequestCard(
    BuildContext context,
    CustomRequest request,
    AppColorTokens colors,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Text(
              request.requestNumber,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: colors.accentVariant.withValues(alpha: 0.15),
              child: Text(
                request.status.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.accentVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Client: ${request.customerName ?? request.customerEmail ?? "Guest"}',
                style: TextStyle(fontSize: 13, color: colors.secondaryText),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            '${request.occasion}  •  ${request.direction}  •  ${request.fabric}  •  ${request.colour}  •  ${dateFormat.format(request.createdAt ?? DateTime.now())}',
            style: TextStyle(fontSize: 12, color: colors.secondaryText),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),

                // Vision & Inspiration
                if (request.inspirationText != null && request.inspirationText!.isNotEmpty) ...[
                  Text('CLIENT VISION STATEMENT', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                  const SizedBox(height: 4),
                  Text('“${request.inspirationText}”', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: colors.primaryText)),
                  const SizedBox(height: 16),
                ],

                // Reference Moodboard Images
                if (request.images.isNotEmpty) ...[
                  Text('REFERENCE MOODBOARD PHOTOGRAPHS (${request.images.length})', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: request.images.length,
                      itemBuilder: (context, idx) {
                        final img = request.images[idx];
                        return Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            image: DecorationImage(
                              image: NetworkImage(img.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Measurements Data (if linked)
                if (request.measurementProfile != null) ...[
                  Text('ATTACHED ANATOMICAL PROFILE: ${request.measurementProfile!.name.toUpperCase()}', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: MeasurementField.allFields
                        .where((f) => request.measurementProfile!.isFieldFilled(f.key))
                        .map((f) {
                      final val = request.measurementProfile!.getValue(f.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: colors.surfaceVariant,
                        child: Text('${f.label}: $val ${request.measurementProfile!.unit}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.primaryText)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Designer Notes
                if (request.designerNotes != null && request.designerNotes!.isNotEmpty) ...[
                  Text('DESIGNER LOG REMARKS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.accentVariant)),
                  const SizedBox(height: 4),
                  Text(request.designerNotes!, style: TextStyle(fontSize: 13, color: colors.primaryText)),
                  const SizedBox(height: 16),
                ],

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (request.status == CustomRequestStatus.requested ||
                        request.status == CustomRequestStatus.underReview ||
                        request.status == CustomRequestStatus.designDiscussion)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ElevatedButton.icon(
                          onPressed: () => AdminQuoteComposerDialog.show(
                            context,
                            request: request,
                            onQuoteIssued: () {
                              ref.invalidate(adminCustomRequestsProvider);
                            },
                          ),
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: const Text('COMPOSE QUOTATION'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accentVariant,
                            foregroundColor: colors.surface,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _openStatusDialog(context, request, colors),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('UPDATE STATUS & NOTES'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryText,
                        foregroundColor: colors.onAccent,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openStatusDialog(BuildContext context, CustomRequest request, AppColorTokens colors) {
    CustomRequestStatus selectedStatus = request.status;
    final notesController = TextEditingController(text: request.designerNotes ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text('Manage Commission: ${request.requestNumber}'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CustomRequestStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Commission Status'),
                      items: CustomRequestStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Designer / Master Tailor Remarks',
                        hintText: 'Enter sketch progress, fabric arrival dates, or client consultation notes...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final repo = ref.read(customAtelierRepositoryProvider);
                    await repo.updateRequestStatus(
                      request.id,
                      selectedStatus,
                      designerNotes: notesController.text.trim(),
                    );
                    ref.invalidate(adminCustomRequestsProvider);
                  },
                  child: const Text('SAVE UPDATES'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
