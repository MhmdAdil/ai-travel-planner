import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(title: const Text('How to use this app')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00796B), Color(0xFF00A896)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.travel_explore, color: Colors.white, size: 32),
                SizedBox(height: 10),
                Text(
                  'Your Sri Lanka travel companion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Plan a personalized journey, discover nearby places, estimate costs and get AI travel help from one app.',
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _Heading('Start in 5 simple steps'),
          const SizedBox(height: 10),
          _StepCard(
            step: '1',
            icon: Icons.route_outlined,
            title: 'Create your trip',
            text:
                'Open Itinerary and enter your start location, destination, dates, budget, number of travellers, interests, accommodation and transport preferences.',
            action: 'Open itinerary',
            onPressed: () => context.go('/itinerary'),
          ),
          _StepCard(
            step: '2',
            icon: Icons.auto_awesome_outlined,
            title: 'Generate a personalized itinerary',
            text:
                'The app builds a day-by-day route using your selected preferences and matched Sri Lanka places and activities.',
            action: 'Plan a trip',
            onPressed: () => context.go('/itinerary'),
          ),
          _StepCard(
            step: '3',
            icon: Icons.payments_outlined,
            title: 'Check your AI cost prediction',
            text:
                'Review estimated accommodation, food, activities and route-based transport costs and compare the predicted total with your budget.',
            action: 'View itinerary',
            onPressed: () => context.go('/itinerary'),
          ),
          _StepCard(
            step: '4',
            icon: Icons.explore_outlined,
            title: 'Discover nearby places',
            text:
                'Use your current location to find nearby attractions and activities and open navigation when you want to travel to a place.',
            action: 'Discover places',
            onPressed: () => context.go('/discover'),
          ),
          _StepCard(
            step: '5',
            icon: Icons.chat_bubble_outline,
            title: 'Ask the AI Travel Assistant',
            text:
                'Ask general Sri Lanka travel questions or questions about your current generated itinerary, budget and predicted travel costs.',
            action: 'Ask AI',
            onPressed: () => context.go('/chat'),
          ),
          const SizedBox(height: 20),
          const _Heading('What you can use this app for'),
          const SizedBox(height: 10),
          const _UseCase(
            icon: Icons.tune_outlined,
            title: 'Personalized planning',
            text: 'Build trips around your dates, budget, group size and travel preferences.',
          ),
          const _UseCase(
            icon: Icons.map_outlined,
            title: 'Day-by-day travel route',
            text: 'See the ordered places and activities planned for each day.',
          ),
          const _UseCase(
            icon: Icons.near_me_outlined,
            title: 'Nearby discovery & navigation',
            text: 'Find useful places around you and start navigation to selected locations.',
          ),
          const _UseCase(
            icon: Icons.currency_exchange_outlined,
            title: 'Travel cost estimation',
            text: 'Estimate major trip costs before travelling and see whether the plan fits your budget.',
          ),
          const _UseCase(
            icon: Icons.smart_toy_outlined,
            title: 'Itinerary-aware chatbot',
            text: 'Ask questions such as “What is on Day 2?” or “Am I within my budget?”',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFDCCF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Generate an itinerary before asking trip-specific chatbot questions. '
                    'That gives the assistant your current trip context.',
                    style: TextStyle(fontSize: 11.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF173B36),
        ),
      );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String step;
  final IconData icon;
  final String title;
  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.teal),
              ),
              const SizedBox(height: 5),
              Text(
                'STEP $step',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(fontSize: 11, height: 1.42, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UseCase extends StatelessWidget {
  const _UseCase({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.orange, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
