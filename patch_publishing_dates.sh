#!/bin/bash

if ! command -v xmlstarlet $> /dev/null
then
    echo "xmlstarlet could not be found, please install xmlstarlet"
    exit 1
fi

# Patch added dates in index.xml to actual publishing dates
# $1 packageName: app package name
# $2 tagName: tag name of the app version
# $3 publishedAt: publishing date
patch_index_xml () {
  local packageName="$1"
  local tagName="$2"
  local publishedAt="$3"

  local indexFile="fdroid/repo/index.xml"
  local tmpIndexFile="tmp/index.xml"
  local xmlPublishedAt="${publishedAt:0:10}"

  xmlstarlet ed \
    -u "/fdroid/application[@id='$packageName']/package/version[.='$tagName']/../added" \
    --value "$xmlPublishedAt" \
    "$indexFile" \
    > "$tmpIndexFile"
  mv $tmpIndexFile $indexFile
}

# Format ISO date to Unix timestamp
# $1 iso_date: ISO date
format_date_as_timestamp () {
  local iso_date="$1"

  if date --version &> /dev/null; then
    # GNU date command (Linux)
    timestamp=$(date -u -d "$iso_date" +"%s%3N")
  else
    # BSD date command (macOS)
    timestamp=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date" +"%s")000
  fi

  echo $timestamp
}

# Patch added dates in index-v1.json to actual publishing dates
# $1 packageName: app package name
# $2 tagName: tag name of the app version
# $3 publishedAt: publishing date
patch_index_v1_json () {
  local packageName="$1"
  local tagName="$2"
  local publishedAt="$3"

  local indexV1="fdroid/repo/index-v1.json"
  local tmpIndexV1="tmp/index-v1.json"
  local timestamp="$(format_date_as_timestamp "$publishedAt")"

  jq '(.packages."'"$packageName"'"[] | select(.versionName=="'"$tagName"'").added) = '"$timestamp"'' \
    "$indexV1" \
    > "$tmpIndexV1"
  mv $tmpIndexV1 $indexV1
}

# Patch added dates in index-v2.json to actual publishing dates
# $1 packageName: app package name
# $2 tagName: tag name of the app version
# $3 publishedAt: publishing date
patch_index_v2_json () {
  local packageName="$1"
  local tagName="$2"
  local publishedAt="$3"

  local indexV2="fdroid/repo/index-v2.json"
  local tmpIndexV2="tmp/index-v2.json"
  local timestamp="$(format_date_as_timestamp "$publishedAt")"

  jq '(.packages["'"$packageName"'"].versions[] | select(.manifest.versionName=="'"$tagName"'")).added = '"$timestamp"'' \
    "$indexV2" \
    > "$tmpIndexV2"

  mv $tmpIndexV2 $indexV2
}

# Patch app dates in index.xml to actual publishing dates
# $1 packageName: app package name
patch_publishing_dates () {
  local packageName="$1"

  local indexFile="fdroid/repo/index.xml"
  local tmpIndexFile="tmp/index.xml"

  local jsonFile="tmp/${packageName}.json"
  local tags=$(jq -r '.[].tagName' "$jsonFile")

  for tagName in $tags; do
    local publishedAt=$(jq -r --arg TAGNAME "$tagName" '.[] | select(.tagName==$TAGNAME) | .publishedAt' "$jsonFile")

    patch_index_xml "$packageName" "$tagName" "$publishedAt"
    patch_index_v1_json "$packageName" "$tagName" "$publishedAt"
    patch_index_v2_json "$packageName" "$tagName" "$publishedAt"
  done
}

patch_publishing_dates com.fsck.k9
