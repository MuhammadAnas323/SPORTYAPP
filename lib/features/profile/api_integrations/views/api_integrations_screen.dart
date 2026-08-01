import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/api_connection.dart';
import '../../../../models/sport_type.dart';
import '../../../../widgets/common/app_buttons.dart';
import '../../../../widgets/common/section_header.dart';
import '../viewmodels/api_integrations_view_model.dart';
import 'widgets/connection_card.dart';

class ApiIntegrationsScreen extends ConsumerWidget {
  const ApiIntegrationsScreen({super.key, this.sportType});

  /// When set, only connections of this sport are shown and the Add flow is
  /// pre-seeded for it.
  final SportType? sportType;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ApiConnection connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text(
          '${connection.label}\n${AppStrings.deleteConfirmBody}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(apiIntegrationsViewModelProvider.notifier)
          .delete(connection.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(apiIntegrationsViewModelProvider);
    final notifier = ref.read(apiIntegrationsViewModelProvider.notifier);
    final visibleConnections = sportType == null
        ? state.connections
        : state.connections
            .where((c) => c.sportType == sportType)
            .toList();
    final cricket = visibleConnections
        .where((c) => c.sportType == SportType.cricket)
        .toList();
    final football = visibleConnections
        .where((c) => c.sportType == SportType.football)
        .toList();
    final other = visibleConnections
        .where((c) => c.sportType == SportType.other)
        .toList();
    final addRoute = switch (sportType) {
      SportType.football => '/profile/api/add?sport=football',
      SportType.cricket => '/profile/api/add?sport=cricket',
      _ => '/profile/api/add',
    };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.apiIntegrationsSection)),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        color: Theme.of(context).colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          children: [
            AppPrimaryButton(
              label: AppStrings.addChannel,
              icon: Icons.add_rounded,
              onPressed: () => context.go(addRoute),
            ),
            const SizedBox(height: AppSizes.lg),
            SectionHeader(
              title: '${visibleConnections.length} saved connection${visibleConnections.length == 1 ? '' : 's'}',
              subtitle: AppStrings.poweredBy,
            ),
            const SizedBox(height: AppSizes.lg),

            if (cricket.isNotEmpty) ...[
              _SportChannelRow(
                sport: SportType.cricket,
                connections: cricket,
                liveByConnection: state.liveByConnection,
                onAdd: () => context.go('/profile/api/add?sport=cricket'),
                onToggleEnabled: notifier.toggleEnabled,
                onReTest: notifier.reTest,
                onEdit: (id) => context.go('/profile/api/edit/$id'),
                onDelete: (connection) =>
                    _confirmDelete(context, ref, connection),
              ),
              const SizedBox(height: AppSizes.xl),
            ],

            if (football.isNotEmpty) ...[
              _SportChannelRow(
                sport: SportType.football,
                connections: football,
                liveByConnection: state.liveByConnection,
                onAdd: () => context.go('/profile/api/add?sport=football'),
                onToggleEnabled: notifier.toggleEnabled,
                onReTest: notifier.reTest,
                onEdit: (id) => context.go('/profile/api/edit/$id'),
                onDelete: (connection) =>
                    _confirmDelete(context, ref, connection),
              ),
              const SizedBox(height: AppSizes.xl),
            ],

            if (other.isNotEmpty) ...[
              _SportChannelRow(
                sport: SportType.other,
                connections: other,
                liveByConnection: state.liveByConnection,
                onAdd: () => context.go('/profile/api/add'),
                onToggleEnabled: notifier.toggleEnabled,
                onReTest: notifier.reTest,
                onEdit: (id) => context.go('/profile/api/edit/$id'),
                onDelete: (connection) =>
                    _confirmDelete(context, ref, connection),
              ),
              const SizedBox(height: AppSizes.xl),
            ],

            if (visibleConnections.isEmpty)
              _EmptyConnectionsBanner(
                sportType: sportType,
                onAddCricket: () =>
                    context.go('/profile/api/add?sport=cricket'),
                onAddFootball: () =>
                    context.go('/profile/api/add?sport=football'),
              ),

            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}

/// One sport's slice of the channel list: header + a horizontally scrollable
/// row of channel cards, with an "Add" tile at the end.
class _SportChannelRow extends StatelessWidget {
  const _SportChannelRow({
    required this.sport,
    required this.connections,
    required this.liveByConnection,
    required this.onAdd,
    required this.onToggleEnabled,
    required this.onReTest,
    required this.onEdit,
    required this.onDelete,
  });

  final SportType sport;
  final List<ApiConnection> connections;
  final Map<String, bool> liveByConnection;
  final VoidCallback onAdd;
  final void Function(String id, bool enabled) onToggleEnabled;
  final void Function(String id) onReTest;
  final void Function(String id) onEdit;
  final void Function(ApiConnection connection) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '${sport.label} channels',
          subtitle: '${connections.length} connected',
        ),
        const SizedBox(height: AppSizes.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final connection in connections)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.lg),
                  child: SizedBox(
                    width: 320,
                    child: ConnectionCard(
                      connection: connection,
                      isLiveNow: liveByConnection[connection.id] ?? false,
                      onToggleEnabled: (enabled) =>
                          onToggleEnabled(connection.id, enabled),
                      onReTest: () => onReTest(connection.id),
                      onEdit: () => onEdit(connection.id),
                      onDelete: () => onDelete(connection),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.pagePadding),
                child: SizedBox(
                  width: 120,
                  child: _AddChannelTile(onTap: onAdd),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyConnectionsBanner extends StatelessWidget {
  const _EmptyConnectionsBanner({
    this.sportType,
    required this.onAddCricket,
    required this.onAddFootball,
  });

  final SportType? sportType;
  final VoidCallback onAddCricket;
  final VoidCallback onAddFootball;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCricket = sportType == null || sportType == SportType.cricket;
    final isFootball = sportType == null || sportType == SportType.football;
    return Column(
      children: [
        const SizedBox(height: AppSizes.lg),
        Icon(Icons.link_off_rounded, size: 44, color: scheme.onSurfaceVariant),
        const SizedBox(height: AppSizes.md),
        Text(
          AppStrings.channelsEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          AppStrings.channelsEmptyBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSizes.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            if (isCricket)
              FilledButton.tonalIcon(
                onPressed: onAddCricket,
                icon: const Icon(Icons.sports_cricket_rounded),
                label: const Text(AppStrings.cricketApi),
              ),
            if (isFootball)
              FilledButton.tonalIcon(
                onPressed: onAddFootball,
                icon: const Icon(Icons.sports_soccer_rounded),
                label: const Text(AppStrings.footballApi),
              ),
          ],
        ),
      ],
    );
  }
}

class _AddChannelTile extends StatelessWidget {
  const _AddChannelTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: scheme.primary),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              AppStrings.addChannel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
