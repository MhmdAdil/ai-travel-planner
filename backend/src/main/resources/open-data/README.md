# Nationwide Sri Lanka OpenStreetMap place index

`sri-lanka-places.json` is a source-linked offline index generated from the official Geofabrik
Sri Lanka OpenStreetMap extract. It contains 23,127 named activity records across the country.
Live OpenStreetMap data queried through Overpass remains the primary source.

The index is used when public Overpass servers are unavailable or incomplete. It contains OSM
place names, categories, coordinates, factual tag-derived descriptions and original OSM links. It
does not contain Google Maps listings, ratings, reviews, photos, prices or copied descriptions.

Dataset snapshot: 23 August 2026. Categories include the original Adventure, Attractions,
Beaches, Culture, Food & Cafes, History, Nature & Parks, Temples and Wildlife groups, plus
waterfalls, rivers, ponds and lakes, rocks and caves, mountains and peaks, farms, forests,
shopping malls, water parks, gardens, camping and picnics, hiking, water sports, boating and
marinas, sports, cinemas and theatres, markets, playgrounds and hot springs. A place appears only when the OSM
extract has a named matching record; a genuine zero-result area is never filled with invented data.

Each record includes:

- `name`, `category`, `description` and `address`
- `latitude` and `longitude`
- a stable `sourceReference`
- a public `sourceUrl`
- a `dataSource` label shown by the API

OpenStreetMap data is available under the ODbL and requires OpenStreetMap contributor attribution.
The dataset was generated from the Sri Lanka PBF published by Geofabrik. When refreshing it, use
the latest official extract and preserve each original OSM element reference. Do not add a
commercial map provider's listings unless its licence and API terms explicitly permit storing and
redistributing them.
