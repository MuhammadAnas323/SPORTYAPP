import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/sport_type.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/section_header.dart';
import '../../auth/viewmodels/auth_view_model.dart';
import '../settings/viewmodels/settings_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your channels stay in your Firebase account. You will be signed '
          'out of this device only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authViewModelProvider.notifier).signOut();
    }
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authViewModelProvider).valueOrNull;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.editProfile),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: AppStrings.nameLabel),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: AppStrings.emailLabel),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );

    if (saved == true) {
      final message = await ref
          .read(authViewModelProvider.notifier)
          .updateProfile(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
          );
      if (message != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _showAddApiSheet(BuildContext context) async {
    final sport = await showModalBottomSheet<SportType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
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
                  AppStrings.chooseApiType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sports_cricket_rounded),
                title: const Text(AppStrings.cricketApi),
                subtitle: const Text(AppStrings.cricketApiHelper),
                onTap: () => Navigator.of(context).pop(SportType.cricket),
              ),
              ListTile(
                leading: const Icon(Icons.sports_soccer_rounded),
                title: const Text(AppStrings.footballApi),
                subtitle: const Text(AppStrings.footballApiHelper),
                onTap: () => Navigator.of(context).pop(SportType.football),
              ),
            ],
          ),
        ),
      ),
    );
    if (sport == null || !context.mounted) return;
    final query = sport == SportType.football
        ? 'sport=football'
        : 'sport=cricket';
    context.go('/profile/api/add?$query');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final notifications = ref.watch(notificationsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.sm,
          AppSizes.pagePadding,
          AppSizes.xxl,
        ),
        children: [
          // ---- Account ---------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  AppAvatar(
                    label: user?.name ?? 'F',
                    size: 56,
                  ),
                  const SizedBox(width: AppSizes.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Guest',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'Local device profile',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editProfile(context, ref),
                    tooltip: AppStrings.editProfile,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // ---- Settings -----------------------------------------------------------
          SectionHeader(title: AppStrings.settingsSection),
          const SizedBox(height: AppSizes.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.api_rounded, color: scheme.primary),
                  title: const Text(AppStrings.addChannel),
                  subtitle: const Text(AppStrings.addChannelBody),
                  trailing: const Icon(Icons.add_circle_outline_rounded),
                  onTap: () => _showAddApiSheet(context),
                ),
                const Divider(
                  height: 1,
                  indent: AppSizes.lg,
                  endIndent: AppSizes.lg,
                ),
                const ListTile(
                  leading: Icon(Icons.brightness_6_outlined),
                  title: Text(AppStrings.theme),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    0,
                    AppSizes.lg,
                    AppSizes.md,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(AppStrings.themeSystem),
                          icon: Icon(Icons.brightness_auto_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(AppStrings.themeLight),
                          icon: Icon(Icons.light_mode_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(AppStrings.themeDark),
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) => ref
                          .read(themeModeProvider.notifier)
                          .setMode(s.first),
                      showSelectedIcon: false,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: AppSizes.lg, endIndent: AppSizes.lg),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text(AppStrings.notificationsLiveStarts),
                  value: notifications.liveStarts,
                  onChanged: (v) => ref
                      .read(notificationsProvider.notifier)
                      .setLiveStarts(v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined),
                  title: const Text(AppStrings.notificationsSounds),
                  value: notifications.sounds,
                  onChanged: (v) =>
                      ref.read(notificationsProvider.notifier).setSounds(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sectionGap),

          // ---- About / Support -----------------------------------------------------
          SectionHeader(title: AppStrings.aboutSection),
          const SizedBox(height: AppSizes.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About SportyApp'),
                  subtitle: const Text(AppStrings.version),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/about'),
                ),
                const Divider(height: 1, indent: AppSizes.lg, endIndent: AppSizes.lg),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text(AppStrings.supportSection),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(AppStrings.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

