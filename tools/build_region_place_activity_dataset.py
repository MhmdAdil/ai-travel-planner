import csv
from pathlib import Path
from math import radians, sin, cos, asin, sqrt

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'backend/src/main/resources/open-data/sri-lanka-place-activities.csv'
OUT = ROOT / 'backend/src/main/resources/open-data/sri-lanka-region-place-activities.csv'

ANCHORS = [
    ('Negombo / Katunayake', 7.2083, 79.8358), ('Colombo', 6.9271, 79.8612),
    ('Bentota', 6.4210, 80.0030), ('Galle / Unawatuna', 6.0329, 80.2168),
    ('Mirissa / Weligama', 5.9483, 80.4716), ('Yala / Tissamaharama', 6.2800, 81.2860),
    ('Udawalawe', 6.4388, 80.8882), ('Ella', 6.8667, 81.0466),
    ('Nuwara Eliya', 6.9497, 80.7891), ('Kandy', 7.2906, 80.6337),
    ('Sigiriya / Dambulla', 7.9570, 80.7603), ('Anuradhapura', 8.3114, 80.4037),
    ('Polonnaruwa', 7.9403, 81.0188), ('Trincomalee', 8.5874, 81.2152),
    ('Arugam Bay', 6.8404, 81.8368), ('Jaffna', 9.6615, 80.0255),
    ('Kalpitiya', 8.2330, 79.7660), ('Kitulgala', 6.9896, 80.4173),
    ('Haputale', 6.7657, 80.9526), ('Ratnapura', 6.6828, 80.3992),
]

REGIONS = {
    'Negombo / Katunayake': [('Western Province', 'Western')],
    'Colombo': [('Western Province', 'Western')],
    'Bentota': [('Southern Province', 'Southern')],
    'Galle / Unawatuna': [('Southern Province', 'Southern')],
    'Mirissa / Weligama': [('Southern Province', 'Southern')],
    'Yala / Tissamaharama': [('Southern Province', 'Southern'), ('Uva / South-East Wildlife', 'Uva/South-East')],
    'Udawalawe': [('Uva / South-East Wildlife', 'Uva/South-East'), ('Sabaragamuwa / Rainforest', 'Sabaragamuwa')],
    'Ella': [('Upcountry / Central Highlands', 'Central Highlands'), ('Uva / South-East Wildlife', 'Uva')],
    'Nuwara Eliya': [('Upcountry / Central Highlands', 'Central')],
    'Kandy': [('Upcountry / Central Highlands', 'Central')],
    'Sigiriya / Dambulla': [('Cultural Triangle / North Central', 'Central/North Central')],
    'Anuradhapura': [('Cultural Triangle / North Central', 'North Central')],
    'Polonnaruwa': [('Cultural Triangle / North Central', 'North Central')],
    'Trincomalee': [('Eastern Province', 'Eastern')],
    'Arugam Bay': [('Eastern Province', 'Eastern'), ('Uva / South-East Wildlife', 'South-East')],
    'Jaffna': [('Northern Province', 'Northern')],
    'Kalpitiya': [('North Western / Wayamba', 'North Western')],
    'Kitulgala': [('Sabaragamuwa / Rainforest', 'Sabaragamuwa')],
    'Haputale': [('Upcountry / Central Highlands', 'Central Highlands'), ('Uva / South-East Wildlife', 'Uva')],
    'Ratnapura': [('Sabaragamuwa / Rainforest', 'Sabaragamuwa')],
}

def km(a,b,c,d):
    r=6371.0088
    p1,p2=radians(a),radians(c)
    dp,dl=radians(c-a),radians(d-b)
    x=sin(dp/2)**2+cos(p1)*cos(p2)*sin(dl/2)**2
    return 2*r*asin(sqrt(x))

def nearest(lat,lon):
    return min(ANCHORS, key=lambda a: km(lat,lon,a[1],a[2]))[0]

with SRC.open(encoding='utf-8', newline='') as src, OUT.open('w', encoding='utf-8', newline='') as dst:
    reader=csv.DictReader(src)
    fields=['travel_region','administrative_group','anchor_region']+reader.fieldnames
    writer=csv.DictWriter(dst, fieldnames=fields)
    writer.writeheader()
    count=0
    for row in reader:
        try:
            anchor=nearest(float(row['latitude']), float(row['longitude']))
        except Exception:
            continue
        for travel_region, admin_group in REGIONS.get(anchor, [('Sri Lanka', 'Unknown')]):
            writer.writerow({'travel_region':travel_region,'administrative_group':admin_group,'anchor_region':anchor,**row})
            count+=1
print(f'Wrote {count:,} region/place/activity records to {OUT}')
