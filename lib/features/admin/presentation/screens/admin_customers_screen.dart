import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';
import 'package:ochanya_gili/features/admin/presentation/widgets/designer_notes_sheet.dart';

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final customersAsync = ref.watch(adminCustomersProvider(_searchQuery));

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
                      'CLIENTELE DIRECTORY',
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
                      'Client registry, anatomical measurements, order history & private notes',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(adminCustomersProvider(_searchQuery)),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('REFRESH'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryText,
                    side: BorderSide(color: colors.border),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      style: TextStyle(color: colors.primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by client name, email, or telephone...',
                        hintStyle: TextStyle(color: colors.secondaryText, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: colors.secondaryText),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = null);
                      },
                    ),
                  ElevatedButton(
                    onPressed: _onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryText,
                      foregroundColor: colors.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('SEARCH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customers Table / List
            customersAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading clients: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
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
                          Icon(Icons.people_outline, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery != null
                                ? 'No clientele matching "$_searchQuery".'
                                : 'No clients registered yet.',
                            style: TextStyle(color: colors.secondaryText, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        color: colors.surfaceVariant,
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: _HeaderCell('CLIENT NAME', colors)),
                            Expanded(flex: 3, child: _HeaderCell('CONTACT EMAIL', colors)),
                            Expanded(flex: 2, child: _HeaderCell('PHONE', colors)),
                            Expanded(flex: 2, child: _HeaderCell('REGISTERED', colors)),
                            Expanded(flex: 2, child: _HeaderCell('COMMISSIONS', colors)),
                            Expanded(flex: 3, child: _HeaderCell('ACTIONS', colors, align: TextAlign.right)),
                          ],
                        ),
                      ),
                      Divider(color: colors.border, height: 1),

                      // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: customers.length,
                        separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, index) {
                          final c = customers[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                // Name & Role badge
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.fullName?.isNotEmpty == true ? c.fullName! : 'Private Client',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                          color: colors.accentVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Email
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    c.email,
                                    style: TextStyle(fontSize: 13, color: colors.secondaryText),
                                  ),
                                ),

                                // Phone
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    c.phone?.isNotEmpty == true ? c.phone! : '—',
                                    style: TextStyle(fontSize: 13, color: colors.secondaryText),
                                  ),
                                ),

                                // Registered
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(c.createdAt),
                                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                                  ),
                                ),

                                // Commissions & Measurements counts
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${c.ordersCount} Orders',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.primaryText),
                                      ),
                                      Text(
                                        '${c.measurementsCount} Profiles',
                                        style: TextStyle(fontSize: 11, color: colors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Measurements button
                                      IconButton(
                                        tooltip: 'Client Measurements',
                                        icon: Icon(Icons.straighten, size: 20, color: colors.primaryText),
                                        onPressed: () => context.go('/admin/customers/${c.id}/measurements'),
                                      ),
                                      const SizedBox(width: 4),

                                      // Private Designer Notes button
                                      IconButton(
                                        tooltip: 'Private Atelier Notes',
                                        icon: Icon(Icons.note_alt_outlined, size: 20, color: colors.accentVariant),
                                        onPressed: () {
                                          DesignerNotesSheet.show(
                                            context,
                                            entityType: 'customer',
                                            entityId: c.id,
                                            entityTitle: 'Client: ${c.fullName ?? c.email}',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  final AppColorTokens colors;
  final TextAlign align;

  const _HeaderCell(this.title, this.colors, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: align,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: colors.primaryText,
      ),
    );
  }
}
