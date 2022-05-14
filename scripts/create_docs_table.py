import re
from glob import glob
from os import path
from datetime import datetime

PREFIX = 'sc-portable_'

def human_readable_size(size, decimal_places=1):
    # https://stackoverflow.com/a/43690506/3770924

    for unit in ['B', 'KB', 'MB', 'GB', 'TB', 'PB']:
        if size < 1024.0 or unit == 'PiB':
            break
        size /= 1024.0
    return f"{size:.{decimal_places}f} {unit}"

def build_table(glob_pattern)
    table = '|Languages|Size|Version|Build Date|Download Link|\n'
    table += '|:-:|:-:|:-:|:-:|:-:|'

    for file in glob(glob_pattern):
        filename = path.splitext(path.basename(file))[0]

        version = re.match(r'^([^_]+)', filename.replace(PREFIX, '')).group(1)
        languages = re.match(r'^([^_]+)', filename.replace(PREFIX, '').replace(version + '_', '')).group(1).split('-')
        download_link = 'https://github.com/olastor/sc-portable/releases/download/%s/%s' % (os.environ['GITHUB_REF_NAME'], path.basename(file))

        table += '\n|%s|%s|%s|%s|%s|%s|' % (
            ', '.join(languages), 
            human_readable_size(path.getsize(file)),
            version, 
            datetime.today().strftime('%Y-%m-%d'),
            '[download](%s)' % (download_link)
        )

    return table

if __name__ == '__main__':
    binaries_table = build_table('*.com')
    search_table = build_table('*.db')

    with open('docs/docs/index.md') as f:
        index_md = f.read()

    with open('docs/docs/index.md', 'w') as f:
        index_md = index_md.replace('{{binaries_table}}', binaries_table)
        index_md = index_md.replace('{{search_table}}', search_table)

        f.write(index_md)
