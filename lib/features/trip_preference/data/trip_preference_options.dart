class TripPreferenceOptions {
  TripPreferenceOptions._();

  static const List<String> regions = [
    'Current Location',
    'Bandaranaike International Airport Arrivals',
    'Colombo',
    'Negombo',
    'Kandy',
    'Galle',
    'Ella',
    'Sigiriya',
    'Nuwara Eliya',
    'Yala',
    'Mirissa',
    'Bentota',
    'Hikkaduwa',
    'Unawatuna',
    'Weligama',
    'Arugam Bay',
    'Trincomalee',
    'Jaffna',
    'Anuradhapura',
    'Polonnaruwa',
    'Dambulla',
    'Matale',
    'Ratnapura',
    'Badulla',
    'Haputale',
    'Bandarawela',
    'Kurunegala',
    'Chilaw',
    'Puttalam',
    'Kalpitiya',
    'Mannar',
    'Mullaitivu',
    'Kilinochchi',
    'Vavuniya',
    'Batticaloa',
    'Ampara',
    'Monaragala',
    'Hambantota',
    'Tangalle',
    'Matara',
    'Kalutara',
    'Panadura',
    'Mount Lavinia',
    'Dehiwala',
    'Moratuwa',
    'Kotte',
    'Battaramulla',
    'Malabe',
    'Maharagama',
    'Nugegoda',
    'Piliyandala',
    'Homagama',
    'Avissawella',
    'Gampaha',
    'Ja-Ela',
    'Kandana',
    'Wattala',
    'Peliyagoda',
    'Kelaniya',
    'Kiribathgoda',
    'Kadawatha',
    'Ragama',
    'Minuwangoda',
    'Veyangoda',
    'Nittambuwa',
    'Warakapola',
    'Kegalle',
    'Mawanella',
    'Peradeniya',
    'Katugastota',
    'Kundasale',
    'Digana',
    'Teldeniya',
    'Watthegama',
    'Gampola',
    'Nawalapitiya',
    'Hatton',
    'Dickoya',
    'Maskeliya',
    'Talawakele',
    'Nanuoaya',
    'Ragala',
    'Walapane',
    'Hanguranketha',
    'Rikillagaskada',
    'Padiyathalawa',
    'Maha Oya',
    'Chenkalady',
    'Eravur',
    'Kalkudah',
    'Valaichchenai',
    'Ottamavadi',
    'Habarana',
    'Kekirawa',
    'Galnewa',
    'Thambuththegama',
    'Eppawala',
    'Nochchiyagama',
    'Medawachchiya',
    'Vavuniya',
    'Mankulam',
    'Paranthan',
    'Elephant Pass',
    'Chavakachcheri',
    'Point Pedro',
    'Kankesanthurai',
    'Kayts',
  ];

  static const List<String> interests = [
    'Beaches',
    'Culture',
    'Wildlife',
    'Adventure',
    'Food',
    'Nature',
    'History',
    'Relaxation',
    'Waterfalls',
    'Mountains & Hills',
    'Agro tourism',
    'Forests & Rainforests',
    'Lakes & Rivers',
    'Temples & Heritage',
    'Viewpoints',
    'Gardens',
    'Caves & Rocks',
  ];

  static const List<String> activities = [
    'Hiking',
    'Surfing',
    'Wildlife safari',
    'Swimming',
    'Cycling',
    'Photography',
    'Food tours',
    'Shopping',
    'Snorkelling & Diving',
    'Whale watching',
    'Bird watching',
    'Boating',
    'Camping',
    'Temple visits',
    'Heritage sightseeing',
    'Tea estate visit',
    'Waterfall visit',
    'Scenic viewpoints',
  ];

  static const List<String> budgetLevels = ['LOW', 'MID', 'HIGH'];

  static const List<String> lowAccommodationTypes = [
    'Hostel / dorm',
    'Homestay',
    'Budget guesthouse',
    'Budget hotel / 1-2 star',
  ];

  static const List<String> midAccommodationTypes = [
    ...lowAccommodationTypes,
    'Mid-range hotel / 3-star',
    'Mid-range villa',
    'Boutique guesthouse',
    'Serviced apartment',
  ];

  static const List<String> highAccommodationTypes = [
    'Mid-range hotel / 3-star',
    'Mid-range villa',
    'Boutique guesthouse',
    'Serviced apartment',
    'Luxury / 4-star hotel',
    'Luxury / 5-star hotel',
    'Luxury resort',
    'Boutique hotel / villa',
    'Private villa',
  ];

  static List<String> accommodationTypesForBudget(String budgetLevel) {
    return switch (budgetLevel.toUpperCase()) {
      'LOW' => lowAccommodationTypes,
      'HIGH' => highAccommodationTypes,
      _ => midAccommodationTypes,
    };
  }

  static List<String> transportModesFor(String budgetLevel, int travellers) {
    final publicCombinations = switch (travellers) {
      <= 4 => const [
          'Public transport + Tuk/Taxi',
          'Public transport + Minivan - Uber/PickMe',
          'Public transport + Van - Uber/PickMe',
        ],
      <= 7 => const [
          'Public transport + Minivan - Uber/PickMe',
          'Public transport + Van - Uber/PickMe',
        ],
      <= 13 => const ['Public transport + Van - Uber/PickMe'],
      14 => const ['Public transport + 2 Minivans - Uber/PickMe'],
      15 => const ['Public transport + Van - Uber/PickMe'],
      _ => const ['Public transport + 2 Vans - Uber/PickMe'],
    };

    if (budgetLevel.toUpperCase() == 'LOW') return publicCombinations;

    final directRideHailing = switch (travellers) {
      <= 4 => const [
          'Tuk/Taxi - Uber/PickMe',
          'Minivan - Uber/PickMe',
          'Van - Uber/PickMe',
        ],
      <= 7 => const [
          'Minivan - Uber/PickMe',
          'Van - Uber/PickMe',
        ],
      <= 13 => const ['Van - Uber/PickMe'],
      14 => const ['2 Minivans - Uber/PickMe'],
      15 => const ['Van - Uber/PickMe'],
      _ => const ['2 Vans - Uber/PickMe'],
    };

    if (budgetLevel.toUpperCase() == 'MID') {
      return [...publicCombinations, ...directRideHailing];
    }

    final privateDriver = switch (travellers) {
      <= 3 => const ['Private driver + Tuk', 'Private driver + Car'],
      4 => const ['Private driver + Car'],
      <= 7 => const ['Private driver + Minivan'],
      <= 13 => const ['Private driver + Van'],
      14 => const ['Private driver + 2 Minivans'],
      15 => const ['Private driver + Van'],
      _ => const ['Private driver + 2 Vans'],
    };

    return [...publicCombinations, ...directRideHailing, ...privateDriver];
  }

  static const List<String> foodPreferences = [
    'Sri Lankan',
    'Vegetarian',
    'Vegan',
    'Seafood',
    'International',
    'No preference',
  ];

  static const List<String> travelPaces = ['Relaxed', 'Balanced', 'Fast'];
}
