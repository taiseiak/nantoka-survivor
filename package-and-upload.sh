#!/bin/bash

# Load .env file
export $(grep -v '^#' .env | xargs)

# Run the package script
./package.sh "$1"

PACKAGE_FILE="packager.yml"
GAME_NAME=$(grep '^name:' $PACKAGE_FILE | awk '{print $2}')
version=$(grep '^version:' $PACKAGE_FILE | awk '{print $2}')
DIST_DIR="dist"
VERSION_DIR="$DIST_DIR/$version"

for file in $VERSION_DIR/*.zip; do
  if [[ "$file" == *"MacOS.zip" ]]; then
    platform="osx"
  elif [[ "$file" == *"Web.zip" ]]; then
    platform="HTML5"
  elif [[ "$file" == *"Win64.zip" ]]; then
    platform="win"
  fi
  echo "butler push $file $ITCH_IO_USERNAME/$GAME_NAME:$platform"
  butler push $file $ITCH_IO_USERNAME/$GAME_NAME:$platform
done

echo "Upload completed!"
