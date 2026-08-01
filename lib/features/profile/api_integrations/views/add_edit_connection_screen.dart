import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/api_connection.dart';
import '../../../../models/auth_style.dart';
import '../../../../models/sport_type.dart';
import '../../../../repositories/providers.dart';
import '../../../../widgets/animations/test_connection_animation.dart';
import '../../../../widgets/common/app_buttons.dart';
import '../../../../widgets/common/app_text_field.dart';
import '../viewmodels/connection_form_view_model.dart';

class AddEditConnectionScreen extends ConsumerStatefulWidget {
  const AddEditConnectionScreen({
    super.key,
    this.connectionId,
    this.initialSportType,
  });

  final String? connectionId;

  /// Pre-selects the sport when adding a new API (e.g. "Cricket API").
  final SportType? initialSportType;

  @override
  ConsumerState<AddEditConnectionScreen> createState() =>
      _AddEditConnectionScreenState();
}

class _AddEditConnectionScreenState
    extends ConsumerState<AddEditConnectionScreen> {
  bool _loaded = false;
  bool _obscureKey = true;

  // Persistent controllers: a controller created fresh on every rebuild (the
  // old `TextEditingController(text: state.label)` pattern) replaces the
  // field's controller on each keystroke, corrupting typing and the caret.
  final _labelController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _headerNameController = TextEditingController();
  final _extraHeadersController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Defer the form initialization out of the build phase. Setting
    // ConnectionFormViewModel.state synchronously in initState throws
    // "Tried to modify a provider while the widget tree was building."
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.connectionId == null) {
        ref
            .read(connectionFormViewModelProvider.notifier)
            .resetForAdd(widget.initialSportType);
      } else {
        _tryLoad();
      }
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _headerNameController.dispose();
    _extraHeadersController.dispose();
    super.dispose();
  }

  void _tryLoad() {
    if (widget.connectionId == null || _loaded) return;
    final conn = ref
        .read(connectionsProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.connectionId)
        .firstOrNull;
    if (conn != null) {
      _loaded = true;
      _labelController.text = conn.label;
      _baseUrlController.text = conn.baseUrl;
      _apiKeyController.text = conn.apiKey;
      _headerNameController.text = conn.headerName ?? '';
      _extraHeadersController.text = conn.extraHeaders.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      ref.read(connectionFormViewModelProvider.notifier).loadForEdit(conn);
    }
  }

  Future<void> _test() async {
    final message = await ref
        .read(connectionFormViewModelProvider.notifier)
        .testConnection();
    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _save() async {
    if (!ref.read(connectionFormViewModelProvider).canSave) return;
    final ok = await ref.read(connectionFormViewModelProvider.notifier).save();
    if (ok && mounted) {
      final sport = ref.read(connectionFormViewModelProvider).sportType;
      context.go(
        sport == SportType.football
            ? '/profile/api/football'
            : '/profile/api/cricket',
      );
    }
  }

  /// Bottom sheet listing every connected API with edit/delete actions. It
  /// watches [connectionsProvider] so deletes reflect immediately.
  Future<void> _showConnectedApis() async {
    final screenContext = context;
    await showModalBottomSheet<void>(
      context: screenContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final connections =
              ref.watch(connectionsProvider).valueOrNull ?? const [];
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      0,
                      AppSizes.lg,
                      AppSizes.sm,
                    ),
                    child: Text(
                      AppStrings.connectedApis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (connections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Text(
                        AppStrings.connectedApisEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: connections.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: AppSizes.lg,
                          endIndent: AppSizes.lg,
                        ),
                        itemBuilder: (context, index) {
                          final connection = connections[index];
                          final isFootball =
                              connection.sportType == SportType.football;
                          return ListTile(
                            leading: Icon(
                              isFootball
                                  ? Icons.sports_soccer_rounded
                                  : Icons.sports_cricket_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              connection.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${connection.sportType.label} · ${connection.baseUrl}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: AppStrings.editConnection,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    screenContext.go(
                                      '/profile/api/edit/${connection.id}',
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: AppStrings.deleteConnection,
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    ref,
                                    connection,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ApiConnection connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text('${connection.label}\n${AppStrings.deleteConfirmBody}'),
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
      await ref.read(connectionsProvider.notifier).delete(connection.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-try loading the connection once the list provider resolves.
    ref.listen(connectionsProvider, (_, _) => _tryLoad());

    final state = ref.watch(connectionFormViewModelProvider);
    final notifier = ref.read(connectionFormViewModelProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isEditing ? AppStrings.editConnection : AppStrings.addChannel,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.lg,
          AppSizes.pagePadding,
          AppSizes.xxl,
        ),
        children: [
          // ---- Top actions ----------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: AppStrings.save,
                  icon: Icons.save_outlined,
                  expanded: false,
                  onPressed: state.canSave ? _save : null,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: AppSecondaryButton(
                  label: AppStrings.connectedApis,
                  icon: Icons.link_rounded,
                  expanded: false,
                  onPressed: _showConnectedApis,
                ),
              ),
            ],
          ),
          if (!state.canSave) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              AppStrings.saveRequired,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: AppSizes.xl),

          AppTextField(
            label: AppStrings.connectionLabel,
            controller: _labelController,
            hint: AppStrings.connectionLabelHint,
            onChanged: notifier.setLabel,
          ),
          const SizedBox(height: AppSizes.lg),
          AppDropdown<SportType>(
            label: AppStrings.sportType,
            value: state.sportType,
            items: const [
              SportType.cricket,
              SportType.football,
            ],
            labelBuilder: (s) => s == SportType.cricket
                ? AppStrings.cricketApi
                : AppStrings.footballApi,
            onChanged: notifier.setSportType,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            AppStrings.sportTypeHelper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSizes.lg),
          AppTextField(
            label: AppStrings.baseUrl,
            controller: _baseUrlController,
            hint: AppStrings.baseUrlHint,
            onChanged: notifier.setBaseUrl,
            keyboardType: TextInputType.url,
            prefixIcon: Icons.language_rounded,
          ),
          const SizedBox(height: AppSizes.lg),
          AppTextField(
            label: AppStrings.apiKey,
            controller: _apiKeyController,
            hint: AppStrings.apiKeyHint,
            onChanged: notifier.setApiKey,
            obscure: _obscureKey,
            obscureToggle: true,
            onToggleObscure: () => setState(() => _obscureKey = !_obscureKey),
            prefixIcon: Icons.key_rounded,
          ),
          const SizedBox(height: AppSizes.lg),
          AppDropdown<AuthStyle>(
            label: AppStrings.authStyle,
            value: state.authStyle,
            items: AuthStyle.values,
            labelBuilder: (a) => a.label,
            onChanged: notifier.setAuthStyle,
          ),
          if (state.needsHeaderName) ...[
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: state.authStyle == AuthStyle.customHeader
                  ? AppStrings.customHeaderName
                  : AppStrings.queryParamName,
              controller: _headerNameController,
              hint: state.authStyle == AuthStyle.customHeader
                  ? AppStrings.customHeaderNameHint
                  : AppStrings.queryParamNameHint,
              onChanged: notifier.setHeaderName,
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          AppTextField(
            label: AppStrings.extraHeaders,
            controller: _extraHeadersController,
            hint: AppStrings.extraHeadersHint,
            onChanged: notifier.setExtraHeaders,
            maxLines: 3,
          ),
          const SizedBox(height: AppSizes.xl),

          // ---- Test connection -------------------------------------------------
          AppPrimaryButton(
            label: state.isTesting
                ? AppStrings.testingConnection
                : AppStrings.testConnection,
            icon: Icons.check_circle_outline_rounded,
            loading: state.isTesting,
            onPressed: state.isTesting || state.isRetryLocked ? null : _test,
          ),

          const SizedBox(height: AppSizes.xl),

          // ---- Test result ------------------------------------------------------
          if (state.testResult != null)
            _TestResultPanel(
              success: state.testResult!.success,
              message: state.testResult!.message,
              latency: state.testResult!.latencyLabel,
              retryRemaining: state.retryRemaining,
            ),
        ],
      ),
    );
  }
}

class _TestResultPanel extends StatelessWidget {
  const _TestResultPanel({
    required this.success,
    required this.message,
    required this.latency,
    this.retryRemaining,
  });

  final bool success;
  final String message;
  final String latency;
  final Duration? retryRemaining;

  String _formatRetryRemaining(Duration duration) {
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    final seconds = duration.inSeconds;
    return '$seconds second${seconds == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: (success ? scheme.primary : scheme.error).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: (success ? scheme.primary : scheme.error)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TestResultAnimation(success: success, size: 44),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success ? AppStrings.testSuccess : AppStrings.testFailure,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: success ? scheme.primary : scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                ),
                if (latency.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Response in $latency',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (retryRemaining != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Retry available in ${_formatRetryRemaining(retryRemaining!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
