import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itineraryTitle)),
      body: Center(child: Text(l10n.itineraryTitle)),
    );
  }
}
