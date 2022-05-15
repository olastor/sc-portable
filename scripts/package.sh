#!/bin/bash

LANGUAGES="$1"
# LANGUAGES_PATTERN="(xct|pra|pgd|lzh|san|pli|$(echo $LANGUAGES | sed 's/,/|/g'))"
LANGUAGES_PATTERN="(pli|$(echo $LANGUAGES | sed 's/,/|/g'))"

BINARY_NAME="$2" # must be in same dir
SQLITE_DB_NAME=$(echo "$BINARY_NAME" | sed 's/\.com/_search-data.db/')

echo $LANGUAGES_PATTERN

find api -type f | grep -vP '(language=|lang=)' > api_include.lst
find api -type f | grep -P "((language=|lang=)$LANGUAGES_PATTERN)" >> api_include.lst

# zip -qr "./$BINARY_NAME" api/
zip -qr "./$BINARY_NAME" -@ < api_include.lst
rm api_include.lst

cd server/

# need to hardcode database filename
cp search.lua ../search.lua.bak
sed -i "s/search\.db/$SQLITE_DB_NAME/" search.lua
zip -qr "../$BINARY_NAME" .
mv ../search.lua.bak search.lua

cd ../client
zip  -qr "../$BINARY_NAME" .

echo "Done!"
