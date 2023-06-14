import json
import requests
import zipfile
import os

# Get geojson with download links (see download link in README)
filename = 'ahn3.geojson'
with open(filename) as f:
    data = json.load(f)

# Loop through geojson features and download tifs (zipped)
if data['type'] == 'FeatureCollection':
    features = data['features']
    for i, feature in enumerate(features):
        # Get download URL from feature properties
        ahn3_5m_dtm_url = feature['properties']['AHN3_5m_DTM']
        # Download the zipped tif-file
        print(f'Downloading... | {i+1}/{len(features)} | url: {ahn3_5m_dtm_url})')
        response = requests.get(ahn3_5m_dtm_url)
        
        # Write response to file
        if response.status_code == 200:
            # Get filename from download URL (last element when splitting with '/')
            zip = ahn3_5m_dtm_url.split('/')[-1]
            with open(zip, 'wb') as f:
                f.write(response.content)
            # Extract zip file into dtms directory
            with zipfile.ZipFile(zip, 'r') as zip_ref:
                zip_ref.extractall('dtms')
            os.remove(zip)
else:
    print("Not a FeatureCollection GeoJSON file.")