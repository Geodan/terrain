import feedparser
import requests

feed = feedparser.parse('https://service.pdok.nl/rws/ahn/atom/dtm_05m.xml')

print('Items: ' + str(len(feed.entries[0].links)))
for entry in feed.entries[0].links:
    if(entry.href.endswith('tif')):
        print('Downloading ' + entry.href)
        requests.get(entry.href)
