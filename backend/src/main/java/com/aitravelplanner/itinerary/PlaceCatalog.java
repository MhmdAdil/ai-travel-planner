package com.aitravelplanner.itinerary;

import java.math.BigDecimal;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
class PlaceCatalog {

    private static PlaceTemplate place(
            String name, String category, String description, int minutes, int cost, double distance) {
        return new PlaceTemplate(
                name,
                category,
                description,
                minutes,
                BigDecimal.valueOf(cost),
                BigDecimal.valueOf(distance));
    }

    private final Map<String, List<PlaceTemplate>> catalog = Map.of(
            "colombo", List.of(
                    place("Gangaramaya Temple", "Culture", "Explore an important Buddhist temple and museum.", 90, 600, 3.0),
                    place("Colombo National Museum", "History", "Discover Sri Lankan history, art and heritage collections.", 120, 2500, 2.5),
                    place("Galle Face Green", "Relaxation", "Walk along the oceanfront and sample local street food.", 90, 1500, 3.5),
                    place("Pettah Market Walk", "Food", "Experience busy markets, local snacks and historic streets.", 120, 1800, 4.0),
                    place("Independence Square", "History", "Visit the memorial hall and surrounding gardens.", 75, 300, 2.0),
                    place("Diyatha Uyana", "Nature", "Relax beside the lake and browse evening food stalls.", 90, 1200, 8.0)),
            "kandy", List.of(
                    place("Temple of the Sacred Tooth Relic", "Culture", "Visit Kandy's most significant cultural landmark.", 120, 3000, 2.0),
                    place("Kandy Lake Walk", "Relaxation", "Enjoy a gentle walk around the historic city lake.", 75, 300, 1.5),
                    place("Royal Botanical Gardens", "Nature", "Explore extensive tropical gardens at Peradeniya.", 180, 3500, 7.0),
                    place("Udawattakele Forest Reserve", "Wildlife", "Take a shaded nature walk above central Kandy.", 150, 2000, 4.0),
                    place("Kandy Cultural Dance Show", "Culture", "Watch traditional Kandyan dance and drumming.", 90, 2500, 2.5),
                    place("Bahirawakanda Temple", "History", "See the hilltop Buddha and panoramic city views.", 75, 800, 3.0)),
            "galle", List.of(
                    place("Galle Fort Walk", "History", "Explore ramparts, bastions and colonial streets.", 150, 800, 2.0),
                    place("Galle Lighthouse", "History", "Visit the landmark lighthouse and coastal ramparts.", 60, 300, 1.0),
                    place("Unawatuna Beach", "Beaches", "Swim or relax at a popular sheltered beach.", 180, 2500, 6.0),
                    place("Jungle Beach", "Adventure", "Take a short trail to a smaller beach cove.", 150, 1800, 8.0),
                    place("Maritime Museum", "Culture", "Learn about southern Sri Lanka's maritime history.", 90, 1800, 1.5),
                    place("Japanese Peace Pagoda", "Relaxation", "Enjoy a peaceful hilltop setting and sea views.", 90, 900, 7.0)),
            "ella", List.of(
                    place("Little Adam's Peak", "Hiking", "Take a scenic and accessible hill-country hike.", 150, 800, 3.0),
                    place("Nine Arch Bridge", "History", "Walk to the iconic railway bridge through tea country.", 120, 600, 4.0),
                    place("Ella Rock", "Adventure", "Complete a longer hike with wide mountain views.", 240, 1800, 6.0),
                    place("Ravana Falls", "Nature", "Visit the roadside waterfall south of Ella.", 75, 900, 7.0),
                    place("Tea Factory Experience", "Culture", "Learn how Ceylon tea is processed and tasted.", 120, 3000, 10.0),
                    place("Ella Town Food Walk", "Food", "Try hill-country cafes and Sri Lankan favourites.", 120, 3000, 2.0)),
            "sigiriya", List.of(
                    place("Sigiriya Rock Fortress", "History", "Climb the UNESCO-listed rock fortress and gardens.", 240, 11000, 2.0),
                    place("Pidurangala Rock", "Hiking", "Hike for an outstanding view of Sigiriya Rock.", 180, 3000, 4.0),
                    place("Dambulla Cave Temple", "Culture", "Explore ancient painted caves and Buddha statues.", 150, 3000, 20.0),
                    place("Village Experience", "Food", "Join a village tour with a traditional local meal.", 180, 5500, 6.0),
                    place("Minneriya Safari", "Wildlife", "Search for elephants and wildlife by jeep.", 240, 16000, 25.0),
                    place("Sigiriya Museum", "History", "Understand the fortress before or after the climb.", 90, 2500, 2.0)),
            "nuwara eliya", List.of(
                    place("Horton Plains and World's End", "Hiking", "Start early for a highland nature hike.", 300, 12000, 30.0),
                    place("Gregory Lake", "Relaxation", "Walk by the lake or enjoy gentle recreation.", 120, 2000, 3.0),
                    place("Pedro Tea Estate", "Culture", "Tour a working tea estate and taste Ceylon tea.", 120, 3500, 5.0),
                    place("Victoria Park", "Nature", "Enjoy landscaped gardens in the centre of town.", 90, 1500, 1.5),
                    place("Lover's Leap Waterfall", "Adventure", "Take a short hike to a scenic waterfall.", 120, 800, 4.0),
                    place("Nuwara Eliya Market", "Food", "Browse local produce and try warm hill-country food.", 90, 1800, 2.0)),
            "yala", List.of(
                    place("Yala National Park Safari", "Wildlife", "Take a guided jeep safari through Yala.", 300, 22000, 20.0),
                    place("Bundala National Park", "Wildlife", "Observe wetland birds, crocodiles and other wildlife.", 240, 15000, 35.0),
                    place("Kirinda Temple", "Culture", "Visit a coastal temple with panoramic views.", 90, 800, 15.0),
                    place("Tissamaharama Lake", "Relaxation", "Enjoy a quiet lakeside walk and sunset.", 90, 700, 10.0),
                    place("Sithulpawwa Rock Temple", "History", "Explore an ancient monastery inside the wilderness.", 150, 1800, 28.0),
                    place("Palatupana Beach", "Beaches", "Relax on the wild coastline near Yala.", 120, 1000, 18.0)));

    List<PlaceTemplate> forRegion(String region) {
        return catalog.getOrDefault(region.toLowerCase(Locale.ROOT), catalog.get("colombo"));
    }
}
