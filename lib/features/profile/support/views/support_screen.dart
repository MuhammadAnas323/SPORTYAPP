import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/common/section_header.dart';

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
          SectionHeader(title: AppStrings.faqTitle),
          const SizedBox(height: AppSizes.sm),
          _FaqTile(
            question: AppStrings.faq1Question,
            answer: AppStrings.faq1Answer,
          ),
          const SizedBox(height: AppSizes.sm),
          _FaqTile(
            question: AppStrings.faq2Question,
            answer: AppStrings.faq2Answer,
          ),
          const SizedBox(height: AppSizes.sm),
          _FaqTile(
            question: AppStrings.faq3Question,
            answer: AppStrings.faq3Answer,
          ),
          const SizedBox(height: AppSizes.xl),
          SectionHeader(title: AppStrings.contactTitle),
          const SizedBox(height: AppSizes.sm),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Text(
                    AppStrings.contactBody,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text(AppStrings.sendFeedback),
                  subtitle: const Text(AppStrings.contactEmail),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () {
                    // Intentionally a local placeholder: opening a mail client
                    // is a future hook (see README "Out of scope").
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
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text(AppStrings.responseTime),
                ),
              ],
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
            'SPORTYAPP is an aggregator/viewer of the APIs you connect. It does '
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline_rounded),
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          0,
          AppSizes.lg,
          AppSizes.lg,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
