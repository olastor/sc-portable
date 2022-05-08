import re
from glob import glob
from os import path

BUILDS_DIR = ''
PREFIX = 'sc-portable_'

def human_readable_size(size, decimal_places=1):
    # https://stackoverflow.com/a/43690506/3770924

    for unit in ['B', 'KB', 'MB', 'GB', 'TB', 'PB']:
        if size < 1024.0 or unit == 'PiB':
            break
        size /= 1024.0
    return f"{size:.{decimal_places}f} {unit}"

if __name__ == '__main__':
    binaries = glob(path.join(BUILDS_DIR, PREFIX + '*.com'))

    table = '|version|languages|search enabled|size|download|\n'
    table += '|:-:|:-:|:-:|:-:|:-:|'
    for binary in binaries:
        filename = path.basename(binary)
        version = re.match(r'^([^_]+)', filename.replace(PREFIX, '')).group(1)
        languages = re.match(r'^([^_]+)', filename.replace(PREFIX, '').replace(version + '_', '')).group(1).split('-')
        no_search = '_nosearch' in filename

        table += '\n|%s|%s|%s|%s|%s|' % (
            version, 
            ', '.join(languages), 
            ':x:' if no_search else ':white_check_mark:',
            human_readable_size(path.getsize(binary)),
            '[download](https://github.com/olastor/sc-portable/raw/production/builds/%)' % (filename)
        )

    with open('docs/docs/index.md') as f:
        index_md = f.read()

    with open('docs/docs/index.md', 'w') as f:
        f.write(index_md.replace('{{table}}', table))



