#!/bin/bash

if ! command -v gh $> /dev/null
then
    echo "gh could not be found, please install GitHub CLI"
    exit 1
fi

if ! command -v jq $> /dev/null
then
    echo "jq could not be found, please install jq - commandline JSON processor"
    exit 1
fi

# Generates a list of versions
# $1 repositoryName: orgName/repositoryName
# $2 packageName: app package name
# $3 isPrerelease: true/false
load_app_versions () {
    local repositoryName="$1"
    local packageName="$2"
    local isPrerelease="$3"

    local filename=tmp/${packageName}

    gh release list \
      -R "$repositoryName" \
      --limit 200 \
      --json=tagName,isPrerelease,publishedAt \
      --jq "[.[] | select(.isPrerelease==$isPrerelease)]" \
      --exclude-drafts \
      > "${filename}".json
}

# Download app from provided versions list
# $1 repositoryName: orgName/repositoryName
# $2 packageName: app package name
# $3 maxDownloads: maximum number of downloads

# $4 outputFileName: will download as ${outputFileName}-versionName.apk
load_apps () {
    local repositoryName="$1"
    local packageName="$2"
    local maxDownloads="$3"

    local targetFolder="fdroid/repo"
    local jsonFile="tmp/${packageName}.json"
    local tags=$(jq -r '.[].tagName' "$jsonFile")

    local count=0

    for tag in $tags; do
      if (( count < maxDownloads )); then
        local fileName="${targetFolder}/${packageName}-${tag}.apk"
        local publishedAt=$(jq -r --arg TAGNAME "$tag" '.[] | select(.tagName==$TAGNAME) | .publishedAt' "$jsonFile")
        local fileDate=$(echo $publishedAt | sed 's/-//g; s/://g; s/T//; s/Z$//; s/[0-9]\{2\}$//')
        gh release download -R $repositoryName $tag -O $fileName --clobber
        touch -t $fileDate $fileName
        ((count++))
      else
        break
      fi
    done
}

# Download metadata from given github repository and folder
# $1 repositoryName: orgName/repositoryName
# $2 folderName: app folder to copy metadata from
# $3 packageName: app package name
update_metadata () {
    local repositoryName="$1"
    local folderName="$2"
    local packageName="$3"

    local repoFolder="tmp/${repositoryName}"
    local sourceFolder="${repoFolder}/${folderName}/fastlane/metadata/android/"
    local targetFolder="fdroid/metadata/$packageName"

    gh repo clone "$repositoryName" "$repoFolder"
    rm -r "${targetFolder}" || true
    cp -r "$sourceFolder" "${targetFolder}"
}

# cleanup any previous downloads
rm -rf tmp

mkdir -p tmp

load_app_versions thunderbird/thunderbird-android com.fsck.k9 true
load_apps thunderbird/thunderbird-android com.fsck.k9 20
update_metadata thunderbird/thunderbird-android app-k9mail com.fsck.k9
