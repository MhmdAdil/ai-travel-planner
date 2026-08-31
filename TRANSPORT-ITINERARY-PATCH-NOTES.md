# Itinerary transport + timing patch

## What this patch changes

- Keeps the in-app OpenStreetMap/OSRM navigation button.
- Adds a separate **Start Google Maps Navigation** button using the installed Google Maps app when available, with a web fallback.
- Uses longer planning durations for large activities: hiking/safari 4h, water sports 3h, mountains/adventure 3.5h, beaches/culture/nature around 2.5h, food around 1.5h. These are itinerary planning defaults, not universal promises; particular places can differ.
- Alternative-place selection changes the displayed place, map coordinates, description, activity cost, transport choices, and recalculates the activity end time using the alternative's duration.
- Adds transport options to every itinerary stop and ranks them by budget. LOW prefers train/bus when the destination corridor supports it, then ride-hailing; MID/HIGH relax that order.
- Adds a generated transport dataset with **132,884 destination/mode records**, tied to the existing 23,127 source-linked OSM places. These are planning option records rather than 132,884 live schedules.

## Transport data interpretation

Official/reference sources used in the design:

- Sri Lanka Railways train schedule: https://railway.gov.lk/web/index.php?id=1024&lang=en&option=com_content&view=article
- Sri Lanka Railways fares/charges: https://www.railway.gov.lk/web/index.php?Itemid=217&id=696&lang=en&option=com_content&view=article
- Sri Lanka Railways seat reservation: https://seatreservation.railway.gov.lk/
- National Transport Commission bus fares: https://www.ntc.gov.lk/Bus_info/bus_fares.php
- PickMe vehicle types: https://pickme.lk/services/ride/
- PickMe ride estimates / package information: https://pickme.lk/how-it-works
- Uber fare estimator methodology: https://www.uber.com/global/en/price-estimate/

The NTC page publishes the current bus-fare revisions and route-wise/fare-stage files. Sri Lanka Railways publishes train lines, schedules and fare/seat-reservation resources. The project does **not** claim that a train or bus shown is a guaranteed live departure. The UI labels train/bus prices as planning estimates and tells the traveller to confirm the current service/fare.

Ride-hailing calculations use the project owner's supplied planning assumptions:

- Tuk Tuk: first 1 km LKR 250; extra km midpoint LKR 90 (user range 80–100), capacity 1–3.
- Car: first 1 km LKR 450; extra km midpoint LKR 125 (user range 100–150), capacity 3–4.
- Minivan: first 1 km LKR 800; extra km midpoint LKR 135 (user range 120–150), capacity 4–7.
- Van: first 1 km LKR 1,500; extra km midpoint LKR 225 (user range 200–250), capacity up to 15.

Because Uber/PickMe use live/upfront pricing that can vary with time, demand, traffic and other factors, these values are intentionally presented as estimates rather than exact live fares.

## Important

The large transport CSV is indexed by OSM source reference at backend startup. It is not rescanned for every itinerary choice, so it avoids the earlier long itinerary-generation delay.
