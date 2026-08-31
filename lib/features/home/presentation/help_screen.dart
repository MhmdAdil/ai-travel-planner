import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calling is not available on this device.')),
        );
      }
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the official website.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(title: const Text('Help & Safety')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          _IntroCard(
            icon: Icons.support_agent_outlined,
            title: 'Need travel help?',
            text:
                'Use these quick support options while travelling in Sri Lanka. '
                'For app-specific questions, you can also ask the AI Travel Assistant.',
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Emergency & tourism contacts'),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.local_police_outlined,
            title: 'Police Emergency',
            value: '119',
            subtitle: 'Island-wide police emergency service',
            onTap: () => _call(context, '119'),
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Suwasariya Ambulance',
            value: '1990',
            subtitle: 'Emergency ambulance service',
            onTap: () => _call(context, '1990'),
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.shield_outlined,
            title: 'Tourist Police Division',
            value: '0112 421 451',
            subtitle: 'Tourist safety and assistance',
            onTap: () => _call(context, '0112421451'),
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.travel_explore_outlined,
            title: 'Sri Lanka Tourism Hotline',
            value: '1912',
            subtitle: 'Tourism information and assistance',
            onTap: () => _call(context, '1912'),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('App support'),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Ask the AI Travel Assistant',
            subtitle:
                'Ask about your itinerary, transport, budget, places or general Sri Lanka travel questions.',
            buttonText: 'Open chat',
            onPressed: () => context.go('/chat'),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.rule_folder_outlined,
            title: 'Read travel rules',
            subtitle:
                'Review important travel guidance before visiting attractions or starting activities.',
            buttonText: 'View rules',
            onPressed: () => context.push('/home/rules'),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Official source'),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.open_in_new,
            title: 'SLTDA Tourist Police',
            subtitle:
                'Open the Sri Lanka Tourism Development Authority Tourist Police page.',
            buttonText: 'Open website',
            onPressed: () => _open(
              context,
              'https://sltda.gov.lk/en/tourist-police',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Emergency and tourism contact information is based on official Sri Lanka Tourism / SLTDA information. '
            'Availability and numbers may change, so verify official sources when possible.',
            style: TextStyle(fontSize: 11, height: 1.45, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF00A896)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.4,
                    fontSize: 12,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF173B36),
        ),
      );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE3EBE8)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Icon(Icons.call_outlined, size: 18, color: AppColors.teal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onPressed,
                  child: Text(buttonText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
