#!/bin/bash

set -e

git clone https://github.com/suttacentral/suttacentral
cd suttacentral
sed -i 's/sc-elasticsearch//g' Makefile
cp "import.py" ./server/server/import.py
make run-preview-env-no-search
export FRONTEND_IMAGE=$(docker ps | grep sc-frontend | cut -d' ' -f1)
docker exec $FRONTEND_IMAGE bash -c "sed -i '/BundleAnalyzerPlugin/d' webpack.common.js && node_modules/.bin/webpack --no-watch --config webpack.prod.js"
docker cp $FRONTEND_IMAGE:/opt/sc/frontend/build .
mv ./build ../client
export FLASK_IMAGE=$(docker ps | grep sc-flask | cut -d' ' -f1)
docker exec $FLASK_IMAGE python3 server/import.py
mv server/out ../api
