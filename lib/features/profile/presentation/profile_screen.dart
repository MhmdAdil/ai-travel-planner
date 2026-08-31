import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../cost_prediction/application/cost_prediction_controller.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryControllerProvider);
    final costState = ref.watch(costPredictionControllerProvider);
    final itinerary = itineraryState.itinerary;
    final preference = itineraryState.lastPreference;
    final prediction = costState.prediction;
    final travellerProfile = ref.watch(travellerProfileProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F8),
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                labelColor: AppColors.tealDark,
                unselectedLabelColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                tabs: [
                  Tab(
                    height: 38,
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.luggage_outlined, size: 17),
                        SizedBox(width: 6),
                        Text('My Trip'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.support_agent_outlined, size: 17),
                        SizedBox(width: 6),
                        Text('Support'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _MyTripTab(
                    profile: travellerProfile,
                    onEditUsername: () => _showEditUsername(context, ref, travellerProfile),
                    onChangePassword: () => _showChangePassword(context, ref),
                    itineraryTitle: itinerary?.title,
                    destination: itinerary?.destinationRegion,
                    days: itinerary?.days.length,
                    arrival: preference?.arrivalDateTime,
                    departure: preference?.departureDateTime,
                    travellers: preference?.groupSize,
                    budget: preference?.budgetLkr,
                    predictedTotal: prediction?.totalPredictedCostLkr,
                    withinBudget: prediction?.withinBudget,
                    budgetDifference: prediction?.budgetDifferenceLkr,
                    onOpenItinerary: () => context.go('/itinerary'),
                  ),
                  _SupportTab(
                    onHelp: () => context.push('/home/help'),
                    onRules: () => context.push('/home/rules'),
                    onHowTo: () => context.push('/home/how-to-use'),
                    onChat: () => context.go('/chat'),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: SafeArea(
                top: false,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, color: AppColors.orange),
                  label: const Text(
                    'Log out',
                    style: TextStyle(color: AppColors.orange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.orange),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUsername(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<TravellerProfile> profile,
  ) async {
    final current = switch (profile) {
      AsyncData<TravellerProfile>(:final value) => value,
      _ => null,
    };
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile is still loading.')),
      );
      return;
    }

    final username = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeUsernameDialog(initialUsername: current.username),
    );

    if (username == null || !context.mounted) return;

    try {
      await ref.read(profileRepositoryProvider).updateUsername(username);
      ref.invalidate(travellerProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully.')),
        );
      }
    } on ProfileException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _showChangePassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final request = await showDialog<_PasswordChangeRequest>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );

    if (request == null || !context.mounted) return;

    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: request.currentPassword,
            newPassword: request.newPassword,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
      }
    } on ProfileException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _ChangeUsernameDialog extends StatefulWidget {
  const _ChangeUsernameDialog({required this.initialUsername});

  final String initialUsername;

  @override
  State<_ChangeUsernameDialog> createState() => _ChangeUsernameDialogState();
}

class _ChangeUsernameDialogState extends State<_ChangeUsernameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change username'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            final username = value?.trim() ?? '';
            if (username.length < 3 || username.length > 30) {
              return 'Use 3-30 characters.';
            }
            if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(username)) {
              return 'Letters, numbers, dot, underscore or hyphen only.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PasswordChangeRequest {
  const _PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => (value?.isNotEmpty ?? false)
                    ? null
                    : 'Enter your current password.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
                validator: (value) => (value?.length ?? 0) >= 8
                    ? null
                    : 'New password must be at least 8 characters.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
                validator: (value) => value == _newController.text
                    ? null
                    : 'Passwords do not match.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                _PasswordChangeRequest(
                  currentPassword: _currentController.text,
                  newPassword: _newController.text,
                ),
              );
            }
          },
          child: const Text('Change password'),
        ),
      ],
    );
  }
}


class _MyTripTab extends StatelessWidget {
  const _MyTripTab({
    required this.profile,
    required this.onEditUsername,
    required this.onChangePassword,
    required this.itineraryTitle,
    required this.destination,
    required this.days,
    required this.arrival,
    required this.departure,
    required this.travellers,
    required this.budget,
    required this.predictedTotal,
    required this.withinBudget,
    required this.budgetDifference,
    required this.onOpenItinerary,
  });

  final AsyncValue<TravellerProfile> profile;
  final VoidCallback onEditUsername;
  final VoidCallback onChangePassword;
  final String? itineraryTitle;
  final String? destination;
  final int? days;
  final DateTime? arrival;
  final DateTime? departure;
  final int? travellers;
  final double? budget;
  final double? predictedTotal;
  final bool? withinBudget;
  final double? budgetDifference;
  final VoidCallback onOpenItinerary;

  @override
  Widget build(BuildContext context) {
    final hasTrip = itineraryTitle != null && arrival != null && departure != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _AccountCard(
          profile: profile,
          onEditUsername: onEditUsername,
          onChangePassword: onChangePassword,
        ),
        const SizedBox(height: 18),
        if (!hasTrip)
          _EmptyTripCard(onPlanTrip: onOpenItinerary)
        else ...[
          _ActiveTripCard(
            destination: (destination?.trim().isNotEmpty ?? false)
                ? destination!.trim()
                : itineraryTitle!,
            days: days ?? 0,
            arrival: arrival!,
            departure: departure!,
            travellers: travellers ?? 1,
            budget: budget ?? 0,
            onOpen: onOpenItinerary,
          ),
          const SizedBox(height: 14),
          if (predictedTotal != null)
            _BudgetCard(
              predictedTotal: predictedTotal!,
              budget: budget ?? 0,
              withinBudget: withinBudget ?? false,
              difference: budgetDifference ?? 0,
              onOpen: onOpenItinerary,
            ),
        ],
        const SizedBox(height: 18),
        const Text(
          'Quick access',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF173B36),
          ),
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.route_outlined,
          title: 'My itinerary',
          subtitle: 'Open or create your personalized travel plan.',
          onTap: onOpenItinerary,
        ),
      ],
    );
  }
}

class _SupportTab extends StatelessWidget {
  const _SupportTab({
    required this.onHelp,
    required this.onRules,
    required this.onHowTo,
    required this.onChat,
  });

  final VoidCallback onHelp;
  final VoidCallback onRules;
  final VoidCallback onHowTo;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00796B), Color(0xFF00A896)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.support_agent_outlined,
                color: Colors.white,
                size: 34,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel support',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Get safety information, official travel guidance and help using the app.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ProfileAction(
          icon: Icons.health_and_safety_outlined,
          title: 'Help & Safety',
          subtitle: 'Emergency contacts, Tourist Police and travel assistance.',
          onTap: onHelp,
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.gavel_outlined,
          title: 'Rules & Regulations',
          subtitle: 'Important Sri Lanka travel rules and official guidance.',
          onTap: onRules,
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.menu_book_outlined,
          title: 'How to use this app',
          subtitle: 'See how to plan, discover, navigate, check costs and use AI.',
          onTap: onHowTo,
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.auto_awesome_outlined,
          title: 'AI Travel Assistant',
          subtitle: 'Ask questions about Sri Lanka or your current trip.',
          onTap: onChat,
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.profile,
    required this.onEditUsername,
    required this.onChangePassword,
  });

  final AsyncValue<TravellerProfile> profile;
  final VoidCallback onEditUsername;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return profile.when(
      loading: () => Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3EBE8)),
        ),
        child: const CircularProgressIndicator(),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3EBE8)),
        ),
        child: const Text('Could not load account details.'),
      ),
      data: (user) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3EBE8)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00796B), Color(0xFF00A896)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF173B36),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditUsername,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Username'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChangePassword,
                    icon: const Icon(Icons.lock_reset_outlined, size: 17),
                    label: const Text('Password'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTripCard extends StatelessWidget {
  const _EmptyTripCard({required this.onPlanTrip});

  final VoidCallback onPlanTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE8)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: AppColors.teal,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No active trip yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create an itinerary and your current trip summary will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onPlanTrip,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Plan a trip'),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({
    required this.destination,
    required this.days,
    required this.arrival,
    required this.departure,
    required this.travellers,
    required this.budget,
    required this.onOpen,
  });

  final String destination;
  final int days;
  final DateTime arrival;
  final DateTime departure;
  final int travellers;
  final double budget;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM');

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.luggage_outlined,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current trip',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF173B36),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open itinerary',
                onPressed: onOpen,
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _InfoStat(
                  label: 'Dates',
                  value:
                      '${dateFormat.format(arrival)} - ${dateFormat.format(departure)}',
                ),
              ),
              Expanded(
                child: _InfoStat(
                  label: 'Duration',
                  value: '$days days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoStat(
                  label: 'Travellers',
                  value: '$travellers',
                ),
              ),
              Expanded(
                child: _InfoStat(
                  label: 'Budget',
                  value: _fullLkr(budget),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.predictedTotal,
    required this.budget,
    required this.withinBudget,
    required this.difference,
    required this.onOpen,
  });

  final double predictedTotal;
  final double budget;
  final bool withinBudget;
  final double difference;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        withinBudget ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDEAE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: AppColors.teal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI cost summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: onOpen,
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _fullLkr(predictedTotal),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF173B36),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Budget: ${_fullLkr(budget)}',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              withinBudget
                  ? 'Within budget by ${_fullLkr(difference.abs())}'
                  : 'Over budget by ${_fullLkr(difference.abs())}',
              style: TextStyle(
                color: statusColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF29433F),
          ),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE8)),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF203E39),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fullLkr(double amount) {
  return 'LKR ${NumberFormat('#,##0').format(amount.round())}';
}
