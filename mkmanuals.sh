#!/bin/bash

build_rfcs=true
build_mediatypes=false
build_drafts=false

#perl rfcsplitter.pl
echo Obtaining StrongCopy
strongcopy=strongcopy
if ! type -p strongcopy 2> /dev/null ; then
    wget -O strongcopy https://github.com/gerph/alexwaugh-strongcopy/releases/download/v1.05/strongcopy-ubuntu-1.05
    chmod +x strongcopy
    strongcopy=$PWD/strongcopy
fi

echo Cleaning construction directories
$build_rfcs && rm -rf sh
$build_drafts && rm -rf shdraft
$build_mediatypes && rm -rf shmedia

if $build_rfcs ; then
    echo Building RFCs StrongHelp
    perl makerfcsh.pl
fi
if $build_drafts ; then
    echo Building Drafts StrongHelp
    perl scandrafts.pl
fi
if $build_mediatypes ; then
    echo Building Media types StrongHelp
    perl scanmedia.pl
fi

echo Creating Manual files
mkdir -p Manuals
if $build_rfcs ; then
    $strongcopy -o Manuals/RFCs,3d6 sh
fi
if $build_drafts ; then
    $strongcopy -o Manuals/InetDrafts,3d6 shdraft
fi
if $build_mediatypes ; then
    $strongcopy -o Manuals/MIMETypes,3d6 shmedia
fi
