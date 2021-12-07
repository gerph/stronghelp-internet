#!/bin/bash
##
# Obtain all the RFCs that we might need.
#
# Syntax: obtain-rfcs.sh [-all]
#
# -all will fetch all the RFCs as well. This is not necessary unless we're actually processing
# these files. Most of the content can be extracted from the rfc-index.xml so there's no need
# to fetch the actual RFCs any more.
#

set -e
set -o pipefail

fetch_all=false

if [[ "$1" = '-all' ]] ; then
    fetch_all=true
fi

rfcsite=https://www.ietf.org/rfc
rfcstore="rfcs"

mkdir -p "$rfcstore"

if [ ! -f "$rfcstore/rfc-index.xml" ] ; then
    wget -O "$rfcstore/rfc-index.xml" $rfcsite/rfc-index.xml
fi
# Build the simplified file which we can extract data from without worrying about namespaces
{
    echo "<rfcs>"
    xmllint --xpath '//*[local-name()="rfc-entry"]' "$rfcstore/rfc-index.xml"
    echo "</rfcs>"
} > "$rfcstore/rfc-index-simple.xml"

if $fetch_all ; then
    while read RFC ; do
        group=$(($(echo $RFC | sed -E s/^0*//)/ 100))
        groupdir="$rfcstore/rfcs${group}00"
        rfcfile="RFC$RFC.txt"
        if [[ ! -f "$groupdir/$rfcfile" && ! -f "$groupdir/$rfcfile.absent" ]] ; then
            echo "Download $RFC -> $groupdir/$rfcfile"
            mkdir -p "$groupdir"
            rm -f rfc$RFC.txt
            if wget --quiet -O rfc$RFC.txt $rfcsite/rfc$RFC.txt ; then
                mv rfc$RFC.txt "$groupdir/$rfcfile"
            else
                echo "Not present"
                # Just create an empty file
                touch "$groupdir/$rfcfile.absent"
            fi
        fi
    done < <(xmllint --xpath '//rfc-entry/doc-id/text()' "$rfcstore/rfc-index-simple.xml" | grep -Eo '\d+')
fi

