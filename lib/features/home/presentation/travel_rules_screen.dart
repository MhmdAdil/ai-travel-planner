import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class TravelRulesScreen extends StatelessWidget {
  const TravelRulesScreen({super.key});

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
      appBar: AppBar(title: const Text('Rules & Regulations')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFDCCF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.orange),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Important travel guidance for visitors to Sri Lanka. '
                    'This page summarizes official Sri Lanka Tourism / SLTDA information; '
                    'laws and entry requirements can change, so always verify the latest official source.',
                    style: TextStyle(fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _RuleCard(
            number: '1',
            icon: Icons.badge_outlined,
            title: 'Visa and entry conditions',
            points: [
              'Foreign visitors must comply with the visa conditions applicable to their nationality and purpose of travel.',
              'Check current visa and entry requirements before departure because conditions can change.',
            ],
          ),
          const _RuleCard(
            number: '2',
            icon: Icons.camera_alt_outlined,
            title: 'Photography at attractions',
            points: [
              'Some attractions and protected sites require permission or a photography permit.',
              'Follow the instructions, signs and ticket conditions at each attraction.',
            ],
          ),
          const _RuleCard(
            number: '3',
            icon: Icons.luggage_outlined,
            title: 'Customs and prohibited imports',
            points: [
              'Declare items when required by Sri Lankan customs rules.',
              'Official tourism guidance states that importing non-prescription drugs and pornography is an offence.',
              'Personal equipment may be subject to declaration requirements on arrival.',
            ],
          ),
          const _RuleCard(
            number: '4',
            icon: Icons.temple_buddhist_outlined,
            title: 'Religious and cultural places',
            points: [
              'Respect instructions at religious, archaeological and cultural sites.',
              'Dress and behave respectfully and follow any site-specific photography or access restrictions.',
            ],
          ),
          const _RuleCard(
            number: '5',
            icon: Icons.hiking_outlined,
            title: 'Adventure and nature activities',
            points: [
              'Use properly operated activities and follow the safety briefing provided by the operator.',
              'At environmentally sensitive areas, follow the stated do\'s and don\'ts and avoid causing pollution or damage.',
            ],
          ),
          const _RuleCard(
            number: '6',
            icon: Icons.receipt_long_outlined,
            title: 'Use legitimate tourism services',
            points: [
              'Prefer registered or legitimate tourism services where possible.',
              'Keep receipts and booking details for accommodation, transport and paid activities.',
            ],
          ),
          const _RuleCard(
            number: '7',
            icon: Icons.shield_outlined,
            title: 'Safety and emergencies',
            points: [
              'Police emergency: 119.',
              'Suwasariya ambulance: 1990.',
              'SLTDA Tourist Police Division: 0112 421 451.',
              'Sri Lanka Tourism information hotline: 1912.',
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Official sources',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF173B36),
            ),
          ),
          const SizedBox(height: 10),
          _SourceButton(
            label: 'SLTDA Tourist Police',
            onPressed: () => _open(context, 'https://sltda.gov.lk/en/tourist-police'),
          ),
          const SizedBox(height: 8),
          _SourceButton(
            label: 'SLTDA Official Website',
            onPressed: () => _open(context, 'https://sltda.gov.lk/en'),
          ),
          const SizedBox(height: 8),
          _SourceButton(
            label: 'Official Sri Lanka Tourism Travel Tips',
            onPressed: () => _open(context, 'https://www.srilanka.travel/travel-tips'),
          ),
          const SizedBox(height: 15),
          const Text(
            'Last content review: August 2026. This is travel guidance, not legal advice.',
            style: TextStyle(fontSize: 10.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.points,
  });

  final String number;
  final IconData icon;
  final String title;
  final List<String> points;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.teal, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF203E39),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 5, color: AppColors.orange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.42,
                        color: Color(0xFF455A56),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.open_in_new, size: 17),
      label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.tealDark,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: const BorderSide(color: Color(0xFFD4E4DF)),
      ),
    );
  }
}
