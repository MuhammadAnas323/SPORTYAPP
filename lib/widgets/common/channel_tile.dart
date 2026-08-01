import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../models/api_connection.dart';
import '../../models/sport_type.dart';
import 'connection_status_pill.dart';
import 'sport_icon.dart';

/// Compact card for one connected API channel — used on the Home "Your
/// channels" carousel. Tap opens its management/edit flow.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.connection,
    this.onTap,
  });

  final ApiConnection connection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFootball = connection.sportType == SportType.football;

    return SizedBox(
      width: 210,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isFootball
                              ? const [Color(0xFF0E7A45), Color(0xFF0B3D2A)]
                              : const [Color(0xFF1B9A63), Color(0xFF0B4D30)],
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: SportIcon(
                        isFootball
                            ? SportIconName.football
                            : SportIconName.bat,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  connection.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        connection.sportType == SportType.football
                            ? 'Football'
                            : 'Cricket',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    ConnectionStatusPill(
                      status: connection.status,
                      liveNow: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
