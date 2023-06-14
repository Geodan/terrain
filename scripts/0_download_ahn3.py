import json
import requests
import zipfile
import os
from urllib.parse import urlparse

filename = 'ahn3.geojson'
with open(filename) as f:
    data = json.load(f)

if data['type'] == 'FeatureCollection':
    features = data['features']
    for feature in features:
        properties = feature['properties']
        ahn3_5m_dtm_url = properties['AHN3_5m_DTM']
        print(ahn3_5m_dtm_url)
        response = requests.get(ahn3_5m_dtm_url)
        if response.status_code == 200:
            a = urlparse(ahn3_5m_dtm_url)
            zip = os.path.basename(a.path)
            with open(zip, 'wb') as f:
                f.write(response.content)

            with zipfile.ZipFile(zip, 'r') as zip_ref:
                zip_ref.extractall('dtm')
            os.remove(zip)
else:
    print("Not a FeatureCollection GeoJSON file.")