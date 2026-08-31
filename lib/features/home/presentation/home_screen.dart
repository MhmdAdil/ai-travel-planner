import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../cost_prediction/application/cost_prediction_controller.dart';
import '../../itinerary/application/itinerary_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryControllerProvider);
    final costState = ref.watch(costPredictionControllerProvider);
    final itinerary = itineraryState.itinerary;
    final preference = itineraryState.lastPreference;
    final prediction = costState.prediction;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI Travel Planner',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'Explore Sri Lanka smarter',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Travel assistant',
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            if (preference != null && itinerary != null) {
              await ref.read(costPredictionControllerProvider.notifier).predict(
                    preference: preference,
                    itinerary: itinerary,
                    force: true,
                  );
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeroCard(
                hasTrip: itinerary != null,
                destination: itinerary?.destinationRegion,
                onPlanTrip: () => context.go('/itinerary'),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Quick actions',
                subtitle: 'Everything you need for your journey',
              ),
              const SizedBox(height: 10),
              _QuickActions(
                onPlan: () => context.go('/itinerary'),
                onDiscover: () => context.go('/discover'),
                onChat: () => context.go('/chat'),
              ),
              const SizedBox(height: 22),
              if (itinerary != null && preference != null) ...[
                const _SectionTitle(
                  title: 'Your current trip',
                  subtitle: 'A quick look at your active travel plan',
                ),
                const SizedBox(height: 10),
                _CurrentTripCard(
                  title: itinerary.title,
                  destination: itinerary.destinationRegion,
                  days: itinerary.days.length,
                  travellers: preference.groupSize,
                  arrival: preference.arrivalDateTime,
                  departure: preference.departureDateTime,
                  budgetLkr: preference.budgetLkr,
                  onOpen: () => context.go('/itinerary'),
                ),
                const SizedBox(height: 16),
              ],
              if (prediction != null) ...[
                _PredictionCard(
                  total: prediction.totalPredictedCostLkr,
                  budget: prediction.userBudgetLkr,
                  difference: prediction.budgetDifferenceLkr,
                  withinBudget: prediction.withinBudget,
                  transport: prediction.transportCostLkr,
                  accommodation: prediction.accommodationCostLkr,
                  food: prediction.foodCostLkr,
                  activities: prediction.activitiesCostLkr,
                  onOpen: () => context.go('/itinerary'),
                ),
                const SizedBox(height: 22),
              ],
              const _SectionTitle(
                title: 'Travel smarter',
                subtitle: 'Help, official travel guidance and app instructions',
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.support_agent_outlined,
                title: 'Help & Safety',
                description:
                    'Get emergency contacts, support options and quick travel help.',
                onTap: () => context.push('/home/help'),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.gavel_outlined,
                title: 'Rules & Regulations',
                description:
                    'Read important Sri Lanka travel guidance based on official tourism sources.',
                onTap: () => context.push('/home/rules'),
              ),
              const SizedBox(height: 10),
              _FeatureTile(
                icon: Icons.menu_book_outlined,
                title: 'How to use this app',
                description:
                    'Learn how to plan trips, discover places, check costs and use the AI assistant.',
                onTap: () => context.push('/home/how-to-use'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.hasTrip,
    required this.destination,
    required this.onPlanTrip,
  });

  final bool hasTrip;
  final String? destination;
  final VoidCallback onPlanTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00796B), Color(0xFF00A896)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -28,
            child: Icon(
              Icons.travel_explore,
              size: 142,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Sri Lanka',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasTrip ? 'Ready for ${destination ?? 'your trip'}?' : 'Where will you go next?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasTrip
                    ? 'Your personalized plan is ready. Open it anytime or create a fresh journey.'
                    : 'Create a personalized Sri Lanka itinerary using your budget, dates and interests.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onPlanTrip,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.tealDark,
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                ),
                icon: Icon(hasTrip ? Icons.map_outlined : Icons.auto_awesome),
                label: Text(hasTrip ? 'Open my itinerary' : 'Plan my trip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173B36),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPlan,
    required this.onDiscover,
    required this.onChat,
  });

  final VoidCallback onPlan;
  final VoidCallback onDiscover;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.route_outlined,
            label: 'Plan trip',
            onTap: onPlan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.explore_outlined,
            label: 'Discover',
            onTap: onDiscover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.chat_bubble_outline,
            label: 'Ask AI',
            onTap: onChat,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6ECEA)),
          ),
          child: Column(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.teal),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF26433F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentTripCard extends StatelessWidget {
  const _CurrentTripCard({
    required this.title,
    required this.destination,
    required this.days,
    required this.travellers,
    required this.arrival,
    required this.departure,
    required this.budgetLkr,
    required this.onOpen,
  });

  final String title;
  final String destination;
  final int days;
  final int travellers;
  final DateTime arrival;
  final DateTime departure;
  final double budgetLkr;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM');
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE4EBE8)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.luggage_outlined, color: AppColors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.isEmpty ? title : destination,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF173B36),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(arrival)} - ${dateFormat.format(departure)}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _TripStat(icon: Icons.calendar_today_outlined, value: '$days', label: 'Days')),
                  Expanded(child: _TripStat(icon: Icons.group_outlined, value: '$travellers', label: 'Travellers')),
                  Expanded(child: _TripStat(icon: Icons.payments_outlined, value: _compactLkr(budgetLkr), label: 'Budget')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: AppColors.teal),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.total,
    required this.budget,
    required this.difference,
    required this.withinBudget,
    required this.transport,
    required this.accommodation,
    required this.food,
    required this.activities,
    required this.onOpen,
  });

  final double total;
  final double budget;
  final double difference;
  final bool withinBudget;
  final double transport;
  final double accommodation;
  final double food;
  final double activities;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final statusColor = withinBudget ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final positiveDifference = difference.abs();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDEAE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_graph, color: AppColors.teal),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI cost prediction',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      'Estimated trip spending',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onOpen, child: const Text('Details')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Predicted total', style: TextStyle(color: Colors.black54, fontSize: 11)),
                    const SizedBox(height: 3),
                    Text(
                      _fullLkr(total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF173B36),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  withinBudget ? 'Within budget' : 'Over budget',
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            withinBudget
                ? '${_fullLkr(positiveDifference)} remaining from ${_fullLkr(budget)} budget'
                : '${_fullLkr(positiveDifference)} above your ${_fullLkr(budget)} budget',
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _CostMini(label: 'Stay', value: accommodation)),
              Expanded(child: _CostMini(label: 'Food', value: food)),
              Expanded(child: _CostMini(label: 'Travel', value: transport)),
              Expanded(child: _CostMini(label: 'Activities', value: activities)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostMini extends StatelessWidget {
  const _CostMini({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _compactLkr(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54)),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
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
            border: Border.all(color: const Color(0xFFE7ECEB)),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF203E39),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, height: 1.35, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

String _compactLkr(double amount) {
  if (amount >= 1000000) {
    return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 1000) {
    return 'LKR ${(amount / 1000).toStringAsFixed(0)}K';
  }
  return 'LKR ${amount.toStringAsFixed(0)}';
}

String _fullLkr(double amount) {
  return 'LKR ${NumberFormat('#,##0').format(amount.round())}';
}
