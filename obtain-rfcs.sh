#!/bin/bash
##
# Obtain all the RFCs that we might need.
#

set -e
set -o pipefail

rfcsite=https://www.ietf.org/rfc
rfcstore="rfcs"

mkdir -p "$rfcstore"

if [ ! -f rfc-index.xml ] ; then
    wget -o "$rfcstore/rfc-index.xml" $rfcsite/rfc-index.xml
fi
# Build the simplified file which we can extract data from without worrying about namespaces
{
    echo "<rfcs>"
    xmllint --xpath '//*[local-name()="rfc-entry"]' rfc-index.xml
    echo "</rfcs>"
} > "$rfcstore/rfc-index-simple.xml"

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
