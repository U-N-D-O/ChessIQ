// DEMO BUTTON - grants 50,000 coins for testing purposes.
// Remove or gate behind a debug flag before shipping to production.
//
// Usage: place DemoCoinsButton() anywhere in the main-menu widget tree.

import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DemoCoinsButton extends StatelessWidget {
  const DemoCoinsButton({super.key});

  Future<void> _claimCoins(BuildContext context) async {
    final economy = context.read<EconomyProvider>();
    await economy.addCoins(50000);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFFD4A017)),
              const SizedBox(width: 8),
              const Text('Demo Coins Added'),
            ],
          ),
          content: Text(
            '50,000 demo coins have been credited to your account.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.86)),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nice'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.monetization_on_rounded),
      label: const Text('+50,000 coins (DEMO)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD4A017),
        foregroundColor: Colors.black,
      ),
      onPressed: () => _claimCoins(context),
    );
  }
}
