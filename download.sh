#!/bin/bash

if ! command -v gh $> /dev/null
then
    echo "gh could not be found, please install GitHub CLI"
    exit 1
fi

# Generates a list of versions
# $1 repository name: orgName/repositoryName
# $2 isPrerelease: true/false
# $3 outputFile
load_app_versions () {
    gh release list -R $1 --limit 200 --json=tagName,isPrerelease --jq ".[] | select(.isPrerelease == $2) | .tagName" --exclude-drafts > $3
}

# Download app from provided versions list
# $1 repository name: orgName/repositoryName
# $2 number of apps to download
# $3 inputFile: filename
# $4 outputFileName: will download as ${outputFileName}-versionName.apk
load_apps () {
    counter=1
    while [ $counter -le $2 ]
    do
        version=$(sed "${counter}q;d" $3)
        file=fdroid/repo/${4}-${version}.apk
        gh release download -R $1 $version -O $file
        ((counter++))
    done
}

# Download metadata from given github repository and folder
# $1 repository name: orgName/repositoryName
# $2 folderName: app folder to copy metadata from
# $3 packageName: used for fdroid app
update_metadata () {
    gh repo clone $1 tmp/$1
    rm -r fdroid/metadata/$3 || true
    cp -r tmp/$1/$2/fastlane/metadata/android/ fdroid/metadata/$3
}

# cleanup any previous downloads
mkdir -p tmp
