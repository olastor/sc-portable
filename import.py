import os
import app
import json

LANGUAGES = ['en']
PALI_LOOKUP_LANGUAGES = ['en', 'es', 'de', 'zh', 'pt', 'id', 'nl']
CHINESE_LOOKUP_LANGUAGES = ['en']

def flush(results):
    for fname, data in results:
        dumpfile = './out' + fname
        os.makedirs(os.path.dirname(dumpfile), exist_ok=True)
        with open(dumpfile, 'w') as f:
            f.write(data)

if __name__ == '__main__':
    client = app.app.test_client()

    urls = []

    for iso_code in LANGUAGES:
        collection = client.get('/pwa/collection/sutta?languages=%s&root_lang=true' % (iso_code)).get_json()

        for menu_id in collection['menu']:
            urls.append('/menu/%s?language=%s' % (menu_id, iso_code))
            urls.append('/suttafullpath/%s?language=%s' % (menu_id, iso_code))

        for sp_id in collection['suttaplex']:
            urls.append('/suttaplex/%s?language=%s' % (sp_id, iso_code))

        for text in collection['texts']:
            for translation in text['translations']:
                for author in translation['authors']:
                    urls.append('/suttas/%s/%s?lang=%s&siteLanguage=%s' % (text['uid'], author, translation['lang'], iso_code))
                    urls.append('/bilarasuttas/%s/%s?lang=%s&siteLanguage=%s' % (text['uid'], author, translation['lang'], iso_code))

        urls.append('/menu/sutta?language=' + iso_code)

        if iso_code in PALI_LOOKUP_LANGUAGES:
            urls.append('/dictionaries/lookup?from=pli&to=' + iso_code)

        if iso_code in CHINESE_LOOKUP_LANGUAGES:
            urls.append('/dictionaries/lookup?from=lhz&to=' + iso_code + '&fallback=false')
            urls.append('/dictionaries/lookup?from=lhz&to=' + iso_code + '&fallback=true')

        urls.append('/tipitaka_menu?language=' + iso_code)

    for text in collection['texts']:
        urls.append('/parallels/%s' % (text['uid']))

    urls.append('/paragraphs')
    urls.append('/expansion')
    urls.append('/root_edition')
    urls.append('/epigraphs')
    urls.append('/shortcuts')
    urls.append('/pali_reference_edition')
    urls.append('/languages?all=true')

    results = []

    bufmax = 10 * 1024 * 1024
    bufsize = 0

    for url in urls:
        res = client.get(url)

        text = res.get_data(as_text=True)
        results.append((url, text))
        bufsize += len(text)

        if bufsize > bufmax:
            print('flushing', bufsize)
            flush(results)
            results = []
            bufsize = 0
            print('flushed')

    flush(results)
