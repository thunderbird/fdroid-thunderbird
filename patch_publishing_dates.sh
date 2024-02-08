#!/bin/bash

if ! command -v xmlstarlet $> /dev/null
then
    echo "xmlstarlet could not be found, please install xmlstarlet"
    exit 1
fi

# Patch app dates in index.xml to actual publishing dates
# $1 packageName: app package name
patch_publishing_dates () {
    local packageName="$1"

    local indexFile="fdroid/repo/index.xml"
    local tmpIndexFile="tmp/index.xml"

    local jsonFile="tmp/${packageName}.json"
    local tags=$(jq -r '.[].tagName' "$jsonFile")

    for tagName in $tags; do
        local publishedAt=$(jq -r --arg TAGNAME "$tagName" '.[] | select(.tagName==$TAGNAME) | .publishedAt[0:10]' "$jsonFile")
        xmlstarlet ed \
          -u "/fdroid/application[@id='$packageName']/package/version[.='$tagName']/../added" \
          --value "$publishedAt" \
          "$indexFile" \
          > "$tmpIndexFile"
        mv $tmpIndexFile $indexFile
    done
}

patch_publishing_dates com.fsck.k9
