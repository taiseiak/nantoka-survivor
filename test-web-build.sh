#!/bin/bash

GAME_NAME=$(basename "$(pwd)")
DIST_DIR="dist"
VERSION=$(grep '^version:' packager.yml | awk '{print $2}')
WEB_ZIP="$DIST_DIR/$VERSION/${GAME_NAME}-${VERSION}-Web.zip"
WEB_DIR="$DIST_DIR/$VERSION/Web"

echo "Uncompressing $WEB_ZIP..."
unzip -o "$WEB_ZIP" -d "$WEB_DIR"

if [ $? -eq 0 ]; then
    echo "Uncompression successful."
else
    echo "Failed to uncompress $WEB_ZIP."
    exit 1
fi

echo "Starting Python HTTP server..."
cd "$WEB_DIR"
python3 -m http.server 8000

echo "Server running at http://localhost:8000"
echo "Press Ctrl+C to stop the server."
