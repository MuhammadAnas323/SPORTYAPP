import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/common/section_header.dart';

/// Developer-mode entry point reached from the hidden avatar gesture.
///
/// Offers the two supported sport API families; tapping one opens the
/// sport-specific [ApiIntegrationsScreen].
class ApiTypePickerScreen extends StatelessWidget {
  const ApiTypePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.apiIntegrationsSection)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.lg,
          AppSizes.pagePadding,
          AppSizes.xxl,
        ),
        children: [
          SectionHeader(title: AppStrings.chooseApiType),
          const SizedBox(height: AppSizes.sm),
          Card(
            child: ListTile(
              leading: Icon(Icons.sports_cricket_rounded,
                  color: scheme.primary),
              title: const Text(AppStrings.cricketApi),
              subtitle: const Text(AppStrings.cricketApisBody),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/profile/api/cricket'),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Card(
            child: ListTile(
              leading: Icon(Icons.sports_soccer_rounded,
                  color: scheme.primary),
              title: const Text(AppStrings.footballApi),
              subtitle: const Text(AppStrings.footballApisBody),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/profile/api/football'),
            ),
          ),
        ],
      ),
    );
  }
}
