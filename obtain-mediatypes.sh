#!/bin/bash
##
# Obtain all the Media type documents that we might need.
#

set -e
set -o pipefail

mediasite=ftp.iana.org
mediapath=/assignments/media-types
mediastore="media-types"

cachezip="http://riscos.online/resources/media-types.zip"=

mkdir -p "$mediastore"

# Speed up the fetching of media types by downloading a cache of all the files
# as of 2021-12-07.
if [ ! -f "media-types.zip" ] ; then
    wget -O media-types.zip "$cachezip"
    unzip media-types.zip
fi

lftp -e "mirror --parallel=3 --verbose $mediapath $mediastore" $mediasite < /dev/null
