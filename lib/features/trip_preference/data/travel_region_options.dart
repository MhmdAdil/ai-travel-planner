class TravelRegionProfile {
  const TravelRegionProfile({
    required this.name,
    required this.places,
    required this.activities,
  });

  final String name;
  final List<String> places;
  final List<String> activities;
}

class TravelRegionOptions {
  TravelRegionOptions._();

  static const List<TravelRegionProfile> profiles = [
    TravelRegionProfile(
      name: 'Western Province',
      places: ['Beaches', 'Culture', 'Food', 'History', 'Relaxation', 'Lakes & Rivers', 'Temples & Heritage', 'Gardens'],
      activities: ['Swimming', 'Photography', 'Food tours', 'Shopping', 'Boating', 'Temple visits', 'Heritage sightseeing', 'Cycling'],
    ),
    TravelRegionProfile(
      name: 'Southern Province',
      places: ['Beaches', 'Culture', 'Wildlife', 'Food', 'Nature', 'History', 'Relaxation', 'Forests & Rainforests', 'Temples & Heritage', 'Viewpoints'],
      activities: ['Surfing', 'Swimming', 'Snorkelling & Diving', 'Whale watching', 'Wildlife safari', 'Bird watching', 'Photography', 'Food tours', 'Boating', 'Heritage sightseeing'],
    ),
    TravelRegionProfile(
      name: 'Upcountry / Central Highlands',
      places: ['Mountains & Hills', 'Waterfalls', 'Agro tourism', 'Nature', 'Culture', 'History', 'Forests & Rainforests', 'Viewpoints', 'Gardens', 'Temples & Heritage', 'Food'],
      activities: ['Hiking', 'Tea estate visit', 'Waterfall visit', 'Scenic viewpoints', 'Photography', 'Bird watching', 'Cycling', 'Temple visits', 'Heritage sightseeing', 'Food tours', 'Camping'],
    ),
    TravelRegionProfile(
      name: 'Cultural Triangle / North Central',
      places: ['Culture', 'History', 'Temples & Heritage', 'Wildlife', 'Nature', 'Lakes & Rivers', 'Viewpoints', 'Food'],
      activities: ['Temple visits', 'Heritage sightseeing', 'Wildlife safari', 'Bird watching', 'Photography', 'Cycling', 'Scenic viewpoints', 'Food tours'],
    ),
    TravelRegionProfile(
      name: 'Eastern Province',
      places: ['Beaches', 'Culture', 'Wildlife', 'Food', 'Nature', 'History', 'Relaxation', 'Lakes & Rivers', 'Temples & Heritage'],
      activities: ['Surfing', 'Swimming', 'Snorkelling & Diving', 'Whale watching', 'Boating', 'Wildlife safari', 'Bird watching', 'Photography', 'Temple visits', 'Food tours'],
    ),
    TravelRegionProfile(
      name: 'Northern Province',
      places: ['Beaches', 'Culture', 'Food', 'History', 'Temples & Heritage', 'Nature', 'Lakes & Rivers'],
      activities: ['Swimming', 'Photography', 'Temple visits', 'Heritage sightseeing', 'Food tours', 'Cycling', 'Bird watching'],
    ),
    TravelRegionProfile(
      name: 'North Western / Wayamba',
      places: ['Beaches', 'Wildlife', 'Nature', 'Culture', 'Food', 'Lakes & Rivers', 'Temples & Heritage', 'Relaxation'],
      activities: ['Whale watching', 'Diving or snorkelling', 'Boating', 'Bird watching', 'Wildlife safari', 'Photography', 'Temple visits', 'Food tours'],
    ),
    TravelRegionProfile(
      name: 'Sabaragamuwa / Rainforest',
      places: ['Forests & Rainforests', 'Waterfalls', 'Mountains & Hills', 'Nature', 'Adventure', 'Wildlife', 'Caves & Rocks', 'Viewpoints', 'Food'],
      activities: ['Hiking', 'Waterfall visit', 'Bird watching', 'Wildlife safari', 'Camping', 'Scenic viewpoints', 'Photography', 'Cycling', 'Food tours'],
    ),
    TravelRegionProfile(
      name: 'Uva / South-East Wildlife',
      places: ['Mountains & Hills', 'Waterfalls', 'Agro tourism', 'Wildlife', 'Nature', 'Adventure', 'Viewpoints', 'Food', 'Culture'],
      activities: ['Hiking', 'Tea estate visit', 'Waterfall visit', 'Wildlife safari', 'Bird watching', 'Camping', 'Scenic viewpoints', 'Photography', 'Cycling', 'Food tours'],
    ),
  ];

  static List<String> get regions => profiles.map((p) => p.name).toList(growable: false);

  static List<String> placesFor(Set<String> selectedRegions) {
    final values = <String>{};
    for (final profile in profiles) {
      if (selectedRegions.contains(profile.name)) values.addAll(profile.places);
    }
    return values.toList()..sort();
  }

  static List<String> activitiesFor(Set<String> selectedRegions, Set<String> selectedPlaces) {
    final values = <String>{};
    for (final profile in profiles) {
      if (selectedRegions.contains(profile.name)) values.addAll(profile.activities);
    }

    // Place-driven refinement keeps activities relevant to what the traveller selected.
    if (selectedPlaces.contains('Beaches')) {
      values.addAll(['Surfing', 'Swimming', 'Snorkelling & Diving', 'Whale watching', 'Boating', 'Photography']);
    }
    if (selectedPlaces.contains('Wildlife')) {
      values.addAll(['Wildlife safari', 'Bird watching', 'Photography']);
    }
    if (selectedPlaces.contains('Mountains & Hills') || selectedPlaces.contains('Viewpoints')) {
      values.addAll(['Hiking', 'Scenic viewpoints', 'Photography', 'Camping']);
    }
    if (selectedPlaces.contains('Waterfalls')) values.addAll(['Waterfall visit', 'Hiking', 'Photography']);
    if (selectedPlaces.contains('Agro tourism')) values.addAll(['Tea estate visit', 'Photography', 'Food tours']);
    if (selectedPlaces.contains('Culture') || selectedPlaces.contains('History') || selectedPlaces.contains('Temples & Heritage')) {
      values.addAll(['Temple visits', 'Heritage sightseeing', 'Photography']);
    }
    if (selectedPlaces.contains('Food')) values.addAll(['Food tours', 'Shopping']);
    if (selectedPlaces.contains('Lakes & Rivers')) values.addAll(['Boating', 'Bird watching', 'Photography']);

    return values.toList()..sort();
  }
}
