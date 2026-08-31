# Stage 2D cost data sources and assumptions

These CSVs contain **reference-derived planning scenarios**, not 50,000 independently observed customer receipts.

## Accommodation
- Sri Lanka Tourism Development Authority accommodation categories: classified tourist hotels (1–5 star), tourist hotels, guest houses, hostels, homestays, boutique hotels/villas, bungalows and apartments.
- SLTDA Year in Review 2023 reports 4,346 registered accommodation establishments and 53,229 rooms in 2023.
- Planning price bands are seeded from current public Sri Lanka travel-cost references and then varied by region/category for ML training.

## Food
- Current Sri Lanka travel-cost references were used as anchors for street food, local restaurants, tourist restaurants, hotel dining and high-end dining.
- The generated rows vary those anchors by region and budget tier.

## Public transport
- National Transport Commission: March 2026 bus-fare revision and route/fare-stage tables.
- Sri Lanka Railways official fare structure uses distance zones and class-specific per-km charges.
- Because exact bus/rail fares depend on route/service/class, the ML dataset uses planning estimates rather than claiming a live ticket quote.

## Uber/PickMe planning assumptions supplied by the project owner
- Tuk Tuk: first km LKR 200; additional km LKR 70–90 (midpoint 80)
- Car: first km LKR 450; additional km LKR 85–110 (midpoint 97.5)
- Minivan: first km LKR 800; additional km LKR 110–130 (midpoint 120)
- Van: first km LKR 1,500; additional km LKR 150–200 (midpoint 175)

## Private driver assumptions supplied by the project owner
- Tuk: LKR 100/km
- Car: LKR 140/km
- Minivan: LKR 190/km
- Van: LKR 250/km

## Capacity logic implemented
- 1–4 travellers: Tuk/Taxi category; 4 uses car capacity rather than a 3-seat tuk.
- 5–7: minivan.
- 8–13: van.
- 14: two minivans.
- 15: van.
- 16–20: two vans.
