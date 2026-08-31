import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../itinerary/data/models/itinerary.dart';
import '../../itinerary/data/models/trip_preference.dart';
import '../application/cost_prediction_controller.dart';
import '../application/cost_prediction_state.dart';
import '../data/models/cost_prediction.dart';

final _lkr = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

class CostPredictionCard extends ConsumerStatefulWidget {
  const CostPredictionCard({
    required this.itinerary,
    required this.preference,
    super.key,
  });

  final Itinerary itinerary;
  final TripPreference preference;

  @override
  ConsumerState<CostPredictionCard> createState() => _CostPredictionCardState();
}

class _CostPredictionCardState extends ConsumerState<CostPredictionCard> {
  @override
  void initState() {
    super.initState();
    _schedulePrediction();
  }

  @override
  void didUpdateWidget(covariant CostPredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.itinerary, widget.itinerary) ||
        !identical(oldWidget.preference, widget.preference)) {
      _schedulePrediction();
    }
  }

  void _schedulePrediction({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(costPredictionControllerProvider.notifier).predict(
            preference: widget.preference,
            itinerary: widget.itinerary,
            force: force,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(costPredictionControllerProvider);
    final prediction = state.prediction;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: AppColors.orange.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Cost Prediction',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (state.status == CostPredictionStatus.success)
                  IconButton(
                    tooltip: 'Refresh XGBoost prediction',
                    onPressed: () => _schedulePrediction(force: true),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Predicted by XGBoost using this itinerary, route distance, travellers and selected preferences.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 14),
            if (state.status == CostPredictionStatus.initial ||
                state.status == CostPredictionStatus.loading) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 10),
              const Text('Calculating AI trip cost…'),
            ] else if (state.status == CostPredictionStatus.error) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage ?? 'Cost prediction failed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _schedulePrediction(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry AI prediction'),
              ),
            ] else if (prediction != null) ...[
              _PredictionRow(
                label: 'Accommodation',
                value: _lkr.format(prediction.accommodationCostLkr),
              ),
              _PredictionRow(
                label: 'Food',
                value: _lkr.format(prediction.foodCostLkr),
              ),
              _PredictionRow(
                label: 'Transport',
                value: _lkr.format(prediction.transportCostLkr),
              ),
              if (prediction.publicTransportKm > 0)
                _BreakdownRow(
                  label: 'Public transport',
                  kilometres: prediction.publicTransportKm,
                  value: prediction.publicTransportCostLkr,
                ),
              if (prediction.privateTransportKm > 0)
                _BreakdownRow(
                  label: 'Uber/PickMe / private vehicle',
                  kilometres: prediction.privateTransportKm,
                  value: prediction.privateTransportCostLkr,
                ),
              _PredictionRow(
                label: 'Activities',
                value: _lkr.format(prediction.activitiesCostLkr),
              ),
              const Divider(height: 22),
              _PredictionRow(
                label: 'Predicted total',
                value: _lkr.format(prediction.totalPredictedCostLkr),
                emphasized: true,
              ),
              _PredictionRow(
                label: 'Your budget',
                value: _lkr.format(prediction.userBudgetLkr),
              ),
              const SizedBox(height: 10),
              _BudgetStatus(prediction: prediction),
              const SizedBox(height: 8),
              Text(
                'Model: ${prediction.model} • Prediction is an estimate, not a guaranteed final travel price.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.kilometres,
    required this.value,
  });

  final String label;
  final double kilometres;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label • ${kilometres.toStringAsFixed(1)} km',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              _lkr.format(value),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
}

class _BudgetStatus extends StatelessWidget {
  const _BudgetStatus({required this.prediction});

  final CostPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final withinBudget = prediction.withinBudget;
    final difference = prediction.budgetDifferenceLkr.abs();
    final color = withinBudget ? Colors.green.shade700 : Colors.red.shade700;
    final icon =
        withinBudget ? Icons.check_circle_outline : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              withinBudget
                  ? 'Within budget by ${_lkr.format(difference)}'
                  : 'Over budget by ${_lkr.format(difference)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
