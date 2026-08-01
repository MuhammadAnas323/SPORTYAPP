import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common/sport_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aboutSection)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.pitchGreen, AppColors.deepGreen],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusCardLg),
              ),
              child: const SportIcon(SportIconName.trophy, size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            AppStrings.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.version,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            AppStrings.aboutBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSizes.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bullet(context, AppStrings.aboutBullet1),
                  _bullet(context, AppStrings.aboutBullet2),
                  _bullet(context, AppStrings.aboutBullet3),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sectionGap),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Text(
                    AppStrings.contactTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text(AppStrings.contactEmail),
                  subtitle: const Text(AppStrings.contactBody),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mail client integration is a future hook. '
                          'Email ${AppStrings.contactEmail}',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: AppSizes.lg, endIndent: AppSizes.lg),
                const ListTile(
                  leading: Icon(Icons.schedule_rounded),
                  title: Text(AppStrings.responseTime),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
