#!/usr/bin/env python3

import json
import time
import random
import re
from os import path, environ
from glob import glob
import sqlite3
from collections import defaultdict
from nltk.stem import PorterStemmer
from nltk.tokenize import sent_tokenize, word_tokenize, RegexpTokenizer
from nltk.corpus import stopwords
import string
import unidecode
from bs4 import BeautifulSoup

tk = RegexpTokenizer(r'\w+')
stemmer = PorterStemmer()

def preprocess(text, lang='en'):
    stem = lambda x: x
    stop = []

    if 'hasdklfjhasldkjhasldkfh' in text:
        text = BeautifulSoup(text).get_text()

    if lang == 'en':
        stem = stemmer.stem
        stop = set(stopwords.words('english'))
    else:
        return []

    tokens = []
    for token in tk.tokenize(text):
        token = token.translate(str.maketrans('', '', string.punctuation + '—'))
        token = token.lower().strip()
        token = stem(token)
        token = unidecode.unidecode(token)
        if len(token) > 0 and not token in stop:
            tokens.append(token)

    return tokens

def get_uid(filename):
    return filename.split('/')[-2]

def get_author(filename):
    return filename.split('/')[-1].split('?')[0]

def get_language(filename):
    return filename.split('lang=')[1].split('&')[0]

if __name__ == '__main__':
    con = sqlite3.connect('example.db')
    cur = con.cursor()

    table_texts_meta = []
    table_search_index = []

    docs_by_tokens = defaultdict(list)
    counts_by_doctoken = {}

    processed_texts = []

    def process(text_data, text_id):
        if text_id in processed_texts:
            return

        tokens = preprocess(text_data, text_id[2])
        table_texts_meta.append(tuple(list(text_id) + [len(tokens)]))

        for token in tokens:
            docs_by_tokens[token].append(text_id)
            
            if not token in counts_by_doctoken:
                counts_by_doctoken[token] = {}

            if not text_id in counts_by_doctoken[token]:
                counts_by_doctoken[token][text_id] = 0

            counts_by_doctoken[token][text_id] += 1

        processed_texts.append(text_id)

    for json_file in glob('api/bilarasuttas/*/*', recursive=True):
        text_id = (get_uid(json_file), get_author(json_file), get_language(json_file))
        text_data = json.loads(open(json_file).read())

        if 'translation_text' in text_data:
            process(' '.join(text_data['translation_text'].values()), text_id)

    for json_file in glob('api/suttas/*/*', recursive=True):
        text_id = (get_uid(json_file), get_author(json_file), get_language(json_file))
        text_data = json.loads(open(json_file).read())

        if not 'root_text' in text_data:
            print('Error no root_text', json_file)
            continue 

        if 'text' in text_data['root_text']:
            process(text_data['root_text']['text'], text_id)

    for token, count_dict in counts_by_doctoken.items():
        frequencies = []
        for tid, count in count_dict.items():
            frequencies.append(tuple(list(tid) + [count]))

        table_search_index.append((token, json.dumps(frequencies)))

    cur.execute("create table texts_meta (text_id, author, language, length)")
    cur.execute("create table search_index (token, frequencies)")
    cur.executemany("insert into texts_meta values (?, ?, ?, ?)", table_texts_meta) 
    cur.executemany("insert into search_index values (?, ?)", table_search_index)
    con.commit()
    con.close()
