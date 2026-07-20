import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../itinerary/application/itinerary_controller.dart';
import '../../itinerary/data/models/trip_preference.dart';
import '../data/trip_preference_options.dart';

class TripPreferenceScreen extends ConsumerStatefulWidget {
  const TripPreferenceScreen({super.key});

  @override
  ConsumerState<TripPreferenceScreen> createState() => _TripPreferenceScreenState();
}

class _TripPreferenceScreenState extends ConsumerState<TripPreferenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  String? _selectedRegion;
  final Set<String> _selectedInterests = {};

  @override
  void dispose() {
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid) return;

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest.')),
      );
      return;
    }

    final preference = TripPreference(
      region: _selectedRegion!,
      budget: double.parse(_budgetController.text.trim()),
      durationDays: int.parse(_durationController.text.trim()),
      interests: _selectedInterests.toList(),
    );

    await ref.read(itineraryControllerProvider.notifier).generate(preference);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(itineraryControllerProvider.select((s) => s.isLoading));

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Your Trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.card_travel, size: 56, color: AppColors.teal),
                const SizedBox(height: 16),
                Text('Tell us about your trip', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  "We'll build a personalized day-by-day itinerary for you.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Destination region',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: TripPreferenceOptions.regions
                      .map((region) => DropdownMenuItem(value: region, child: Text(region)))
                      .toList(),
                  onChanged: isLoading ? null : (value) => setState(() => _selectedRegion = value),
                  validator: (value) => value == null ? 'Please select a region.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Budget (USD)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    final budget = double.tryParse(value?.trim() ?? '');
                    return (budget != null && budget > 0) ? null : 'Enter a valid budget.';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Trip duration (days)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (value) {
                    final days = int.tryParse(value?.trim() ?? '');
                    return (days != null && days > 0) ? null : 'Enter a valid number of days.';
                  },
                ),
                const SizedBox(height: 24),
                Text('Interests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TripPreferenceOptions.interests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: isLoading
                          ? null
                          : (selected) => setState(() {
                                if (selected) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              }),
                      selectedColor: AppColors.orange,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? AppColors.orange : Colors.grey.shade300),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Generate Itinerary'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
