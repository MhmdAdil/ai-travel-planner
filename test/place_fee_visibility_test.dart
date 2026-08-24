import 'package:ai_travel_planner_frontend/features/discover/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

Place place({
  required String feeStatus,
  required String feeDetails,
  double? cost,
}) {
  return Place(
    id: '1',
    name: 'Test place',
    category: 'Attraction',
    description: '',
    averageCostLkr: cost,
    averageCostUsd: null,
    feeStatus: feeStatus,
    feeDetails: feeDetails,
    address: '',
    openingHours: '',
    website: '',
    phone: '',
    latitude: 6.9,
    longitude: 79.8,
    distanceKm: 1,
    dataSource: 'OPENSTREETMAP',
    sourceUrl: null,
  );
}

void main() {
  test('hides unknown or unavailable cost information', () {
    expect(place(feeStatus: 'UNKNOWN', feeDetails: 'Cost unavailable').hasVerifiedFee, isFalse);
    expect(place(feeStatus: 'PAID', feeDetails: 'Cost information is not available').hasVerifiedFee,
        isFalse);
  });

  test('shows genuine free and paid fee information', () {
    expect(place(feeStatus: 'FREE', feeDetails: 'Free entry').hasVerifiedFee, isTrue);
    expect(place(feeStatus: 'PAID', feeDetails: 'Entry fee: LKR 500').hasVerifiedFee, isTrue);
    expect(place(feeStatus: 'PAID', feeDetails: '', cost: 500).hasVerifiedFee, isTrue);
  });
}
