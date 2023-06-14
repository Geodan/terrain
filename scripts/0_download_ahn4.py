import feedparser
import requests
import shutil

feed = feedparser.parse('https://service.pdok.nl/rws/ahn/atom/dtm_05m.xml')

print('Items: ' + str(len(feed.entries[0].links)))
for entry in feed.entries[0].links:
    if(entry.href.endswith('tif')):
        print('Downloading ' + entry.href)
        response = requests.get(entry.href, stream=True)
        with open('dtms/' + entry.href.split('/')[-1], 'wb') as out_file:
            shutil.copyfileobj(response.raw, out_file)