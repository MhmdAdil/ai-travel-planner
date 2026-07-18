import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: AppColors.orange),
              label: Text(
                l10n.logoutButton,
                style: const TextStyle(color: AppColors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.orange),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
