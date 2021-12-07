#!/bin/bash
##
# Obtain all the Media type documents that we might need.
#

set -e
set -o pipefail

mediasite=ftp.iana.org
mediapath=/assignments/media-types
mediastore="media-types"

mkdir -p "$mediastore"

lftp -e "mirror --parallel=3 --verbose $mediapath $mediastore" $mediasite < /dev/null
