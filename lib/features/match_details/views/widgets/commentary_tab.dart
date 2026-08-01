import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/commentary_item.dart';
import '../../../../widgets/common/empty_state.dart';

/// Commentary tab — ball-by-ball / minute-by-minute from the source.
class CommentaryTab extends StatelessWidget {
  const CommentaryTab({super.key, required this.items});

  final List<CommentaryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: AppStrings.tabCommentary,
          body: AppStrings.noCommentary,
          compact: true,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final phase = item.phase;
        final isHighlight = item.isHighlight;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: phase != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: AppSizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.16)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          phase,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isHighlight
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                      )
                    : Text(
                        AppFormatters.relative(item.timestamp),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isHighlight)
                      Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isHighlight
                                  ? Icons.bolt_rounded
                                  : Icons.circle,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'KEY MOMENT',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      item.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            fontWeight: isHighlight
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
