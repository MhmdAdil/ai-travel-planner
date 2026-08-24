const Map<String, Set<String>> discoverActivityFilters = {
  'Temples': {'Temples'},
  'Beaches': {'Beaches'},
  'Nature & Parks': {
    'Nature', 'Relaxation', 'Wildlife', 'Waterfalls', 'Rivers',
    'Ponds & Lakes', 'Rocks & Caves', 'Mountains & Peaks', 'Forests',
    'Gardens', 'Hot Springs',
  },
  'Museums & History': {'Culture', 'History'},
  'Food & Cafes': {'Food'},
  'Adventure & Viewpoints': {
    'Adventure', 'Hiking', 'Cycling', 'Water Sports', 'Camping & Picnics',
    'Rocks & Caves', 'Mountains & Peaks', 'Waterfalls', 'Boating & Marinas',
  },
  'Attractions': {
    'Attraction', 'Water Parks', 'Wildlife', 'Cinemas & Theatres',
    'Markets', 'Shopping Malls', 'Playgrounds',
  },
  'Waterfalls': {'Waterfalls'},
  'Rivers': {'Rivers'},
  'Ponds & Lakes': {'Ponds & Lakes'},
  'Rocks & Caves': {'Rocks & Caves'},
  'Mountains & Peaks': {'Mountains & Peaks'},
  'Farms': {'Farms'},
  'Forests': {'Forests'},
  'Shopping Malls': {'Shopping Malls'},
  'Water Parks': {'Water Parks'},
  'Wildlife & Zoos': {'Wildlife'},
  'Gardens': {'Gardens'},
  'Camping & Picnics': {'Camping & Picnics'},
  'Hiking & Trails': {'Hiking'},
  'Cycling': {'Cycling'},
  'Surfing & Water Sports': {'Water Sports'},
  'Boating & Marinas': {'Boating & Marinas'},
  'Sports & Recreation': {'Sports'},
  'Cinemas & Theatres': {'Cinemas & Theatres'},
  'Markets': {'Markets'},
  'Playgrounds': {'Playgrounds'},
  'Hot Springs': {'Hot Springs'},
};

bool matchesDiscoverActivityFilters(
  String placeCategory,
  Set<String> selectedFilters,
) {
  if (selectedFilters.isEmpty) return true;
  final normalizedCategory = placeCategory.trim().toLowerCase();
  return selectedFilters.any((filter) {
    final acceptedCategories = discoverActivityFilters[filter] ?? const <String>{};
    return acceptedCategories.any(
      (category) => category.toLowerCase() == normalizedCategory,
    );
  });
}
