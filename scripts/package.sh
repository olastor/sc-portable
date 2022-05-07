#!/bin/bash

LANGUAGES="$1"
LANGUAGES_PATTERN="(xct|pra|pgd|lzh|san|pli|$(echo $LANGUAGES | sed 's/,/|/g'))"

BINARY_NAME="$2" # must be in same dir

echo $LANGUAGES_PATTERN

find api -type f | grep -vP '(language=|lang=)' > api_include.lst
find api -type f | grep -P "((language=|lang=)$LANGUAGES_PATTERN)" >> api_include.lst

zip -qr "./$BINARY_NAME" api/
zip -qr "./$BINARY_NAME" -@ < api_include.lst
rm api_include.lst

cd server/
zip "../$BINARY_NAME" .

cd ../client
zip  -qr "../$BINARY_NAME" .

echo "Done!"
