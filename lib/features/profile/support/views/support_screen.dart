import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.supportSection)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Text(
            AppStrings.supportBody,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSizes.xl),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: const Text(AppStrings.sendFeedback),
              subtitle: const Text(AppStrings.contactEmail),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () {
                // Intentionally a local placeholder: opening a mail client is a
                // future hook (see README "Out of scope").
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
          ),
          const SizedBox(height: AppSizes.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text(AppStrings.documentation),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Docs live with your connected APIs.')),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            'SportyApp is an aggregator/viewer of the APIs you connect. It does '
            'not scrape, record, or rebroadcast third-party live streams.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
