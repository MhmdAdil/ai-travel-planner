import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  final _startLocationController = TextEditingController(
    text: 'Bandaranaike International Airport',
  );
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedRegion;
  String _budgetLevel = 'MID';
  int _groupSize = 1;
  String _accommodation = TripPreferenceOptions.accommodationTypes[1];
  String _foodPreference = TripPreferenceOptions.foodPreferences.first;
  String _transportMode = TripPreferenceOptions.transportModes.first;
  String _pace = 'Balanced';
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedActivities = {};

  late DateTime _arrivalDateTime;
  late DateTime _departureDateTime;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _arrivalDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    _departureDateTime = _arrivalDateTime.add(const Duration(days: 3, hours: 9));
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _durationDays {
    final arrival = DateTime(
      _arrivalDateTime.year,
      _arrivalDateTime.month,
      _arrivalDateTime.day,
    );
    final departure = DateTime(
      _departureDateTime.year,
      _departureDateTime.month,
      _departureDateTime.day,
    );
    return departure.difference(arrival).inDays + 1;
  }

  Future<void> _selectArrival() async {
    final value = await _pickDateTime(_arrivalDateTime);
    if (value == null || !mounted) return;
    setState(() {
      _arrivalDateTime = value;
      if (!_departureDateTime.isAfter(value)) {
        _departureDateTime = value.add(const Duration(days: 1, hours: 8));
      }
    });
  }

  Future<void> _selectDeparture() async {
    final value = await _pickDateTime(_departureDateTime);
    if (value == null || !mounted) return;
    if (!value.isAfter(_arrivalDateTime)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure must be after arrival.')),
      );
      return;
    }
    setState(() => _departureDateTime = value);
  }

  Future<DateTime?> _pickDateTime(DateTime current) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate = current.isBefore(firstDate) ? firstDate : current;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInterests.isEmpty) {
      _showMessage('Please select at least one place interest.');
      return;
    }
    if (_selectedActivities.isEmpty) {
      _showMessage('Please select at least one activity.');
      return;
    }
    if (_durationDays > 30) {
      _showMessage('Trips can contain a maximum of 30 days.');
      return;
    }

    final preference = TripPreference(
      destinationRegion: _selectedRegion!,
      startLocation: _startLocationController.text.trim(),
      arrivalDateTime: _arrivalDateTime,
      departureDateTime: _departureDateTime,
      budgetLevel: _budgetLevel,
      budgetLkr: double.parse(_budgetController.text.trim()),
      groupSize: _groupSize,
      interests: _selectedInterests.toList(),
      activities: _selectedActivities.toList(),
      accommodationType: _accommodation,
      foodPreference: _foodPreference,
      transportMode: _transportMode,
      pace: _pace,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    await ref.read(itineraryControllerProvider.notifier).generate(preference);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(itineraryControllerProvider.select((state) => state.isLoading));
    final dateFormat = DateFormat('EEE, d MMM yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Your Trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 48, color: AppColors.teal),
                const SizedBox(height: 12),
                Text('Tell us about your journey', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Your arrival and departure days are included in the day-by-day plan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Route and timing'),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startLocationController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Arrival / starting location',
                    prefixIcon: Icon(Icons.flight_land),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter your starting location.'
                      : null,
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  label: 'Arrival date and time',
                  value: dateFormat.format(_arrivalDateTime),
                  icon: Icons.login,
                  onTap: isLoading ? null : _selectArrival,
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  label: 'Departure date and time',
                  value: dateFormat.format(_departureDateTime),
                  icon: Icons.logout,
                  onTap: isLoading ? null : _selectDeparture,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    '$_durationDays days, including arrival and departure',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Budget and travellers'),
                TextFormField(
                  controller: _budgetController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total trip budget (LKR)',
                    helperText: 'Results show LKR and approximate USD.',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final budget = double.tryParse(value?.trim() ?? '');
                    return (budget != null && budget > 0) ? null : 'Enter a valid budget.';
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _budgetLevel,
                        decoration: const InputDecoration(labelText: 'Budget level'),
                        items: TripPreferenceOptions.budgetLevels
                            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) => setState(() => _budgetLevel = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _groupSize,
                        decoration: const InputDecoration(labelText: 'Travellers'),
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: isLoading ? null : (value) => setState(() => _groupSize = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Places you want to experience'),
                _ChoiceChips(
                  options: TripPreferenceOptions.interests,
                  selected: _selectedInterests,
                  enabled: !isLoading,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Activities you want to do'),
                _ChoiceChips(
                  options: TripPreferenceOptions.activities,
                  selected: _selectedActivities,
                  enabled: !isLoading,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Travel style'),
                _PreferenceDropdown(
                  label: 'Accommodation',
                  icon: Icons.hotel_outlined,
                  value: _accommodation,
                  options: TripPreferenceOptions.accommodationTypes,
                  enabled: !isLoading,
                  onChanged: (value) => setState(() => _accommodation = value),
                ),
                const SizedBox(height: 12),
                _PreferenceDropdown(
                  label: 'Food preference',
                  icon: Icons.restaurant_outlined,
                  value: _foodPreference,
                  options: TripPreferenceOptions.foodPreferences,
                  enabled: !isLoading,
                  onChanged: (value) => setState(() => _foodPreference = value),
                ),
                const SizedBox(height: 12),
                _PreferenceDropdown(
                  label: 'Transport',
                  icon: Icons.directions_bus_outlined,
                  value: _transportMode,
                  options: TripPreferenceOptions.transportModes,
                  enabled: !isLoading,
                  onChanged: (value) => setState(() => _transportMode = value),
                ),
                const SizedBox(height: 12),
                _PreferenceDropdown(
                  label: 'Travel pace',
                  icon: Icons.speed,
                  value: _pace,
                  options: TripPreferenceOptions.travelPaces,
                  enabled: !isLoading,
                  onChanged: (value) => setState(() => _pace = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  enabled: !isLoading,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Extra preferences (optional)',
                    hintText: 'Accessibility, early starts, places to avoid…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(isLoading ? 'Building your plan…' : 'Generate Day-by-Day Plan'),
                ),
                const SizedBox(height: 8),
                Text(
                  'This milestone uses a rule-based baseline. AI and live places integration come next.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          child: Text(value),
        ),
      );
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selected.contains(option);
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: enabled
                ? (value) {
                    value ? selected.add(option) : selected.remove(option);
                    onChanged();
                  }
                : null,
            selectedColor: AppColors.orange,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
          );
        }).toList(),
      );
}

class _PreferenceDropdown extends StatelessWidget {
  const _PreferenceDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: options
            .map((option) => DropdownMenuItem(value: option, child: Text(option)))
            .toList(),
        onChanged: enabled ? (selected) => onChanged(selected!) : null,
      );
}
