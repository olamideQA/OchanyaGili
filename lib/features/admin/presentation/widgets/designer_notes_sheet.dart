import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';
import 'package:ochanya_gili/features/admin/domain/models/admin_dashboard_models.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';

class DesignerNotesSheet extends ConsumerStatefulWidget {
  final String entityType; // 'customer' | 'order' | 'custom_request' | 'appointment'
  final String entityId;
  final String entityTitle;

  const DesignerNotesSheet({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
  });

  static void show(
    BuildContext context, {
    required String entityType,
    required String entityId,
    required String entityTitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DesignerNotesSheet(
        entityType: entityType,
        entityId: entityId,
        entityTitle: entityTitle,
      ),
    );
  }

  @override
  ConsumerState<DesignerNotesSheet> createState() => _DesignerNotesSheetState();
}

class _DesignerNotesSheetState extends ConsumerState<DesignerNotesSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<DesignerNote> _notes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(adminRepositoryProvider);
      final notes = await repo.getDesignerNotes(
        entityType: widget.entityType,
        entityId: widget.entityId,
      );
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final newNote = await repo.addDesignerNote(
        entityType: widget.entityType,
        entityId: widget.entityId,
        content: text,
        createdBy: user.id,
      );

      _noteController.clear();
      if (mounted) {
        setState(() {
          _notes = [newNote, ..._notes];
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteDesignerNote(noteId);
      if (mounted) {
        setState(() {
          _notes.removeWhere((n) => n.id == noteId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20, color: colors.accentVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INTERNAL ATELIER DESIGNER NOTES',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: colors.primaryText,
                          ),
                        ),
                        Text(
                          widget.entityTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Security Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: colors.accentVariant.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: colors.accentVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confidential. These notes are strictly protected by Postgres RLS and never exposed to clients.',
                      style: TextStyle(fontSize: 11, color: colors.primaryText, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Notes list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colors.primaryText))
                  : _error != null
                      ? Center(child: Text('Error: $_error', style: TextStyle(color: colors.error)))
                      : _notes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_note, size: 48, color: colors.secondaryText.withValues(alpha: 0.4)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No atelier notes recorded yet.',
                                    style: TextStyle(color: colors.secondaryText),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _notes.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final note = _notes[index];
                                return Container(
                                  padding: const EdgeInsets.all(16),
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
                                          Text(
                                            note.createdByName ?? 'Atelier Staff',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 0.8,
                                              color: colors.primaryText,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                DateFormat('dd MMM yyyy, HH:mm').format(note.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.secondaryText,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () => _deleteNote(note.id),
                                                child: Icon(Icons.delete_outline, size: 16, color: colors.error),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      minLines: 1,
                      style: TextStyle(color: colors.primaryText, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Record private atelier observation, client preference, or fitting note...',
                        hintStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colors.primaryText),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _addNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryText,
                        foregroundColor: colors.surface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'SAVE NOTE',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
