import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/custom_atelier/data/custom_atelier_repository.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';

class CustomerCustomRequestsScreen extends ConsumerWidget {
  const CustomerCustomRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Please sign in to view your bespoke custom requests.',
                style: TextStyle(color: colors.primaryText),
              ),
            );
          }

          final requestsAsync = ref.watch(userCustomRequestsProvider(user.id));

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
                              'ATELIER BESPOKE COMMISSIONS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: colors.accentVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'My Custom Requests',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track individual commissions, design discussions, sketches, and salon fittings.',
                              style: TextStyle(fontSize: 14, color: colors.secondaryText),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/create-your-look'),
                          icon: Icon(Icons.add, size: 16, color: colors.onAccent),
                          label: const Text('CREATE NEW LOOK'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // List of Requests
                    requestsAsync.when(
                      loading: () => Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Center(child: CircularProgressIndicator(color: colors.primaryText)),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (requests) {
                        if (requests.isEmpty) {
                          return _buildEmptyState(context, colors);
                        }

                        return Column(
                          children: requests.map((req) => _buildRequestCard(context, req, colors)).toList(),
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

  Widget _buildEmptyState(BuildContext context, AppColorTokens colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.brush_outlined, size: 56, color: colors.accentVariant),
          const SizedBox(height: 16),
          Text(
            'NO BESPOKE COMMISSIONS YET',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Collaborate directly with our master tailors and head designer. From gala evening gowns to ceremonial two-pieces, we sculpt your vision from pure textiles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.6, color: colors.secondaryText),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/create-your-look'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('START CREATING YOUR LOOK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, CustomRequest request, AppColorTokens colors) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return InkWell(
      onTap: () => context.go('/account/custom-requests/${request.id}'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: colors.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      request.requestNumber,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusChip(request.status, colors),
                  ],
                ),
                Text(
                  request.createdAt != null ? dateFormat.format(request.createdAt!) : '',
                  style: TextStyle(fontSize: 12, color: colors.secondaryText),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('OCCASION: ', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                          Text(request.occasion, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primaryText)),
                          const SizedBox(width: 16),
                          Text('SILHOUETTE: ', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                          Text(request.direction, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primaryText)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('FABRIC: ', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                          Text(request.fabric, style: TextStyle(fontSize: 13, color: colors.primaryText)),
                          const SizedBox(width: 16),
                          Text('SHADE: ', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: colors.secondaryText)),
                          Text(request.colour, style: TextStyle(fontSize: 13, color: colors.primaryText)),
                        ],
                      ),
                      if (request.inspirationText != null && request.inspirationText!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('“${request.inspirationText}”', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colors.secondaryText)),
                      ],
                      if (request.designerNotes != null && request.designerNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: colors.surfaceVariant,
                          child: Text('Designer Remarks: ${request.designerNotes}', style: TextStyle(fontSize: 12, color: colors.accentVariant)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (request.images.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      image: DecorationImage(
                        image: NetworkImage(request.images.first.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildStatusChip(CustomRequestStatus status, AppColorTokens colors) {
    Color bg;
    Color fg;

    switch (status) {
      case CustomRequestStatus.requested:
      case CustomRequestStatus.underReview:
        bg = colors.accentVariant.withValues(alpha: 0.15);
        fg = colors.accentVariant;
        break;
      case CustomRequestStatus.designDiscussion:
      case CustomRequestStatus.quoteSent:
      case CustomRequestStatus.customerApproved:
        bg = colors.primaryText.withValues(alpha: 0.1);
        fg = colors.primaryText;
        break;
      case CustomRequestStatus.payment:
      case CustomRequestStatus.production:
      case CustomRequestStatus.fitting:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        break;
      case CustomRequestStatus.ready:
      case CustomRequestStatus.delivered:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        break;
      default:
        bg = colors.surfaceVariant;
        fg = colors.secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
