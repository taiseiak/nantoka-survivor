#!/bin/bash

PACKAGE_FILE="packager.yml"
GAME_NAME=$(grep '^name:' $PACKAGE_FILE | awk '{print $2}')

increment_version() {
  local version=$1
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  patch=$((patch + 1))
  echo "$major.$minor.$patch"
}

rm -rf "dist"

OS_TYPE=$(uname)

if [[ "$1" == "--increment-version" ]]; then
  current_version=$(grep '^version:' $PACKAGE_FILE | awk '{print $2}')
  new_version=$(increment_version $current_version)
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS
    sed -i '' "s/^version:.*/version: $new_version/" $PACKAGE_FILE
  elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux
    sed -i "s/^version:.*/version: $new_version/" $PACKAGE_FILE
  fi
  echo "Version incremented to $new_version"
fi

npx love-packager package

echo "Packaging completed!"
