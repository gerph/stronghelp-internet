# StrongHelp manual generation for Internet manuals.

## Introduction

This repository holds some scripts which can generate StrongHelp manuals for resources
used by Internet applications. Specifically there is generation for:

* Index of RFCs.
* Internet drafts (not currently working).
* Media types.
* Internet assignments (not currently working).

## Prerequisites

These tools are intended to be used on Unix systems (Linux, or macOS). They will require:

* `wget`
* `xmllint`
* `perl`
* `gcc` or equivalent compiler
* `make`
* `lftp`
* `unzip`
* Perl's File::Slurp


To build the manuals, it is necessary to first obtain the resources which will be used.
In the large configuration, this means downloading a lot of data - this is turned off by
default.

* RFCs: Around 500MB.
* Drafts: (not currently working).
* Media types: Around 10MB.
* Internet assignments: (not currently working).

To download this content, run the scripts to download the content:

    ./obtain-rfcs.sh
    ./obtain-mediatypes.sh

This will populate the directories with the sources needed to generate the manuals.

## Building the manuals.

Building the manuals can be achieved by running the `mkmanuals.sh` script, once the
resources have all been downloaded.

This will use the content from the downloaded directories (eg `rfcs`) and create
StrongHelp structured content in the `sh` directory. These will then be built into
manuals in the `Manuals` directory.
