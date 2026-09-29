import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';

class AtelierTimelineWidget extends StatelessWidget {
  final List<AtelierTimelineStage> stages;

  const AtelierTimelineWidget({super.key, required this.stages});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isLast = index == stages.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Node & Line
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    // Node Icon / Circle
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stage.isCompleted
                            ? colors.primaryText
                            : stage.isCurrent
                                ? colors.accentVariant
                                : colors.surface,
                        border: Border.all(
                          color: stage.isCompleted
                              ? colors.primaryText
                              : stage.isCurrent
                                  ? colors.accentVariant
                                  : colors.border,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: stage.isCompleted
                            ? Icon(Icons.check, size: 16, color: colors.onAccent)
                            : stage.isCurrent
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.onAccent,
                                    ),
                                  )
                                : Text(
                                    '${stage.stageNumber}',
                                    style: TextStyle(
                                      color: colors.secondaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                    // Vertical Line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: stage.isCompleted ? colors.primaryText : colors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Column 2: Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stage Title & Status Pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              stage.title,
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 16,
                                fontWeight: stage.isCurrent || stage.isCompleted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: stage.isPending
                                    ? colors.secondaryText
                                    : colors.primaryText,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (stage.isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.accentVariant.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                'CURRENT STAGE',
                                style: TextStyle(
                                  color: colors.accentVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        stage.subtitle,
                        style: TextStyle(
                          color: stage.isCurrent ? colors.accentVariant : colors.secondaryText,
                          fontSize: 13,
                          fontWeight: stage.isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        stage.description,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),

                      // Timestamp if completed
                      if (stage.completedAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 13, color: colors.secondaryText),
                            const SizedBox(width: 6),
                            Text(
                              dateFormat.format(stage.completedAt!),
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Atelier craftsman notes
                      if (stage.notes != null && stage.notes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            border: Border(left: BorderSide(color: colors.accentVariant, width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ATELIER LOG NOTE:',
                                style: TextStyle(
                                  color: colors.accentVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stage.notes!,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
