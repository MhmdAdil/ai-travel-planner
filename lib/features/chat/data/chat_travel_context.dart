import '../../cost_prediction/data/models/cost_prediction.dart';
import '../../itinerary/data/models/itinerary.dart';
import '../../itinerary/data/models/trip_preference.dart';

class ChatTravelContextBuilder {
  ChatTravelContextBuilder._();

  static String build({
    TripPreference? preference,
    Itinerary? itinerary,
    CostPrediction? prediction,
  }) {
    if (preference == null && itinerary == null && prediction == null) {
      return '';
    }

    final buffer = StringBuffer();

    if (preference != null) {
      buffer.writeln('TRIP PREFERENCES');
      buffer.writeln('Start location: ${preference.startLocation}');
      buffer.writeln('Destination region: ${preference.destinationRegion}');
      buffer.writeln('Arrival: ${preference.arrivalDateTime.toIso8601String()}');
      buffer.writeln('Departure: ${preference.departureDateTime.toIso8601String()}');
      buffer.writeln('Duration: ${preference.durationDays} days');
      buffer.writeln('Budget: LKR ${preference.budgetLkr.toStringAsFixed(0)} (${preference.budgetLevel})');
      buffer.writeln('Travellers: ${preference.groupSize}');
      buffer.writeln('Regions: ${preference.travelRegions.join(', ')}');
      buffer.writeln('Interests: ${preference.interests.join(', ')}');
      buffer.writeln('Activities: ${preference.activities.join(', ')}');
      buffer.writeln('Accommodation: ${preference.accommodationType}');
      buffer.writeln('Food: ${preference.foodPreference}');
      buffer.writeln('Transport strategy: ${preference.transportMode}');
      buffer.writeln('Pace: ${preference.pace}');
      buffer.writeln('Finish at CMB airport: ${preference.returnToAirport ? 'Yes' : 'No'}');
      if (preference.notes?.trim().isNotEmpty == true) {
        buffer.writeln('Extra preferences: ${preference.notes!.trim()}');
      }
      buffer.writeln();
    }

    if (itinerary != null) {
      buffer.writeln('CURRENT GENERATED ITINERARY');
      buffer.writeln('Title: ${itinerary.title}');
      buffer.writeln('Destination: ${itinerary.destinationRegion}');

      var includedItems = 0;
      const maxItems = 30;
      for (final day in itinerary.days) {
        buffer.writeln('Day ${day.dayNumber}${day.theme.isEmpty ? '' : ' - ${day.theme}'}');
        for (final item in day.items) {
          if (includedItems >= maxItems) break;
          buffer.writeln(
            '- ${item.startTime}-${item.endTime}: ${item.name} | ${item.category} | ${item.location} | '
            '${item.distanceKm.toStringAsFixed(1)} km travel leg | '
            '${item.travelMinutes} min travel | ${item.visitMinutes} min visit',
          );
          includedItems++;
        }
        if (includedItems >= maxItems) {
          buffer.writeln('- Additional itinerary items omitted from chatbot context for size.');
          break;
        }
      }
      buffer.writeln();
    }

    if (prediction != null) {
      buffer.writeln('AI COST PREDICTION');
      buffer.writeln('Accommodation: LKR ${prediction.accommodationCostLkr.toStringAsFixed(0)}');
      buffer.writeln('Food: LKR ${prediction.foodCostLkr.toStringAsFixed(0)}');
      buffer.writeln('Transport: LKR ${prediction.transportCostLkr.toStringAsFixed(0)}');
      buffer.writeln('Public transport: ${prediction.publicTransportKm.toStringAsFixed(1)} km, LKR ${prediction.publicTransportCostLkr.toStringAsFixed(0)}');
      buffer.writeln('Private/Uber/PickMe: ${prediction.privateTransportKm.toStringAsFixed(1)} km, LKR ${prediction.privateTransportCostLkr.toStringAsFixed(0)}');
      buffer.writeln('Activities: LKR ${prediction.activitiesCostLkr.toStringAsFixed(0)}');
      buffer.writeln('Predicted total: LKR ${prediction.totalPredictedCostLkr.toStringAsFixed(0)}');
      buffer.writeln('User budget: LKR ${prediction.userBudgetLkr.toStringAsFixed(0)}');
      buffer.writeln('Within budget: ${prediction.withinBudget ? 'Yes' : 'No'}');
      buffer.writeln('Budget difference: LKR ${prediction.budgetDifferenceLkr.toStringAsFixed(0)}');
    }

    return buffer.toString().trim();
  }
}
