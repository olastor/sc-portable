#!/usr/bin/env python3

import json
import time
import random
import re
from os import path, environ
from glob import glob
import sqlite3
from collections import defaultdict
import string
from bs4 import BeautifulSoup

DB_NAME = 'search.db'

def get_uid(filename):
    return filename.split('/')[-2]

def get_author(filename):
    return filename.split('/')[-1].split('?')[0]

def get_language(filename):
    return filename.split('lang=')[1].split('&')[0]

def get_tokenizer(language):
    if language == 'en':
        return 'porter unicode61'
    else:
        return 'unicode61 remove_diacritics 2'

if __name__ == '__main__':
    con = sqlite3.connect(DB_NAME)
    cur = con.cursor()

    table_text_search = defaultdict(list)
    processed_texts = []

    languages = set()
    for json_file in glob('api/bilarasuttas/*/*', recursive=True):
        lang = get_language(json_file)
        author = get_author(json_file)
        text_id = get_uid(json_file)
        text_data = json.loads(open(json_file).read())

        if 'translation_text' in text_data:
            text = ' '.join(text_data['translation_text'].values())
            table_text_search[lang].append((text_id, author, text))

        if lang == 'pli' and 'root_text' in text_data:
            text = ' '.join(text_data['root_text'].values())
            table_text_search[lang].append((text_id, author, text))

    for json_file in glob('api/suttas/*/*', recursive=True):
        lang = get_language(json_file)
        author = get_author(json_file)
        text_id = get_uid(json_file)
        text_data = json.loads(open(json_file).read())

        if not 'root_text' in text_data:
            print('Error no root_text', json_file)
            continue 

        if 'text' in text_data['root_text']:
            text = BeautifulSoup(text_data['root_text']['text']).get_text()
            table_text_search[lang].append((text_id, author, text))

    for lang, items in table_text_search.items():
        tokenizer = get_tokenizer(lang)
        cur.execute("CREATE VIRTUAL TABLE text_search_%s USING fts5(text_id UNINDEXED, author UNINDEXED, text, tokenize = '%s')" % (lang, tokenizer))
        cur.executemany("insert into text_search_%s values (?, ?, ?)" % (lang), table_text_search[lang])

    con.commit()
    con.close()
