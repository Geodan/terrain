import feedparser
import requests
import shutil
import os

out_dir = 'dtms/'

feed = feedparser.parse('https://service.pdok.nl/rws/ahn/atom/dtm_05m.xml')
# Extract all links that end with 'tif'
links = [l for l in feed.entries[0].links if l.href.endswith('tif')]
print('Items to download: ' + str(len(links)))

for entry in links:
    filename = out_dir + entry.href.split('/')[-1]
    if os.path.exists(filename):
        print(f'File {filename} already exists. Skipping.')
        continue
    print('Downloading ' + entry.href)
    response = requests.get(entry.href, stream=True)
    with open(filename, 'wb') as out_file:
        shutil.copyfileobj(response.raw, out_file)

