"""Normalize the public Sri Lanka 'Information for Accommodation.csv' file.

Usage:
  python tools/normalize_accommodation_csv.py "C:/path/Information for Accommodation.csv"

The official/Kaggle copy contains about 2,130 accommodation records. This script does not
manufacture duplicate rows to reach an arbitrary count; it preserves real rows with usable
coordinates and writes a clean app-ready CSV.
"""
from __future__ import annotations
import csv
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit('Pass the downloaded "Information for Accommodation.csv" path.')

src = Path(sys.argv[1])
out = Path(__file__).resolve().parents[1] / 'backend/src/main/resources/open-data/sri-lanka-accommodations.csv'

with src.open('r', encoding='utf-8-sig', errors='replace', newline='') as f:
    reader = csv.DictReader(f)
    rows = []
    for row in reader:
        try:
            lat = float((row.get('Latitude') or '').strip())
            lng = float((row.get('Logitiute') or row.get('Longitude') or '').strip())
        except ValueError:
            continue
        name = (row.get('Name') or '').strip()
        if not name:
            continue
        rows.append({
            'name': name,
            'type': (row.get('Type') or '').strip(),
            'address': (row.get('Address') or '').strip(),
            'rooms': (row.get('Rooms') or '').strip(),
            'grade': (row.get('Grade') or '').strip(),
            'district': (row.get('District') or '').strip(),
            'latitude': lat,
            'longitude': lng,
        })

out.parent.mkdir(parents=True, exist_ok=True)
with out.open('w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys() if rows else [
        'name','type','address','rooms','grade','district','latitude','longitude'])
    writer.writeheader()
    writer.writerows(rows)
print(f'Wrote {len(rows)} real accommodation rows to {out}')
