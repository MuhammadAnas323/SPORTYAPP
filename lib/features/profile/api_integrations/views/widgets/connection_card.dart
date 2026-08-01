import 'package:flutter/material.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../models/api_connection.dart';
import '../../../../../models/connection_status.dart';
import '../../../../../models/sport_type.dart';
import '../../../../../widgets/common/connection_status_pill.dart';
import '../../../../../widgets/common/sport_icon.dart';

/// One saved API connection in the integrations list.
class ConnectionCard extends StatelessWidget {
  const ConnectionCard({
    super.key,
    required this.connection,
    required this.isLiveNow,
    required this.onToggleEnabled,
    required this.onReTest,
    required this.onEdit,
    required this.onDelete,
  });

  final ApiConnection connection;
  final bool isLiveNow;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onReTest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFootball = connection.sportType == SportType.football;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFootball
                            ? const [Color(0xFF0E7A45), Color(0xFF0B3D2A)]
                            : const [Color(0xFF1B9A63), Color(0xFF0B4D30)],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: SportIcon(
                      isFootball ? SportIconName.football : SportIconName.bat,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connection.baseUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ConnectionStatusPill(
                    status: connection.status,
                    liveNow: isLiveNow,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Key (masked) + last error.
              Row(
                children: [
                  const Icon(Icons.key_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.maskSecret(connection.apiKey),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const Spacer(),
                  if (connection.lastTestedAt != null)
                    Text(
                      'Tested ${AppFormatters.relative(connection.lastTestedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),

              if (connection.status == ConnectionStatus.failed &&
                  connection.lastError != null) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm + 2,
                    vertical: AppSizes.sm - 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    connection.lastError!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.sm),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),

              Row(
                children: [
                  // Enable/disable toggle.
                  _IconAction(
                    icon: connection.enabled
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    tooltip: connection.enabled ? 'Pause' : 'Enable',
                    onTap: () => onToggleEnabled(!connection.enabled),
                  ),
                  _IconAction(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Re-test',
                    onTap: onReTest,
                  ),
                  _IconAction(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                  const Spacer(),
                  _IconAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    color: scheme.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20, color: color ?? scheme.onSurfaceVariant),
    );
  }
}
