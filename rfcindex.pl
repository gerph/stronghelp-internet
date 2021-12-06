#! /usr/bin/perl

# $rfc_<var>{<number>} are assigned by rfcindex_read
# <var> can be :
#  title     (the title itself)
#  authors   (list of authors)
#  date      ('dd mmm yyyy' or 'mmm yyyy')
#  length    (in bytes)
#  format    (TXT,PS)
#  status    (INFORMATIONAL, etc)
#  obsoletes (comma separated list of RFC numbers)
#  obsoleted (comma separated list of RFC numbers)
#  updates   (comma separated list of RFC numbers)
#  updated   (comma separated list of RFC numbers)
#  also      (comma separated list of RFC numbers)

use File::Slurp;

use warnings;

my $rfcstore = "rfcs";

sub rfcfile
{
    my ($num) = @_;
    $num =~ s/RFC//;
    $num =~ s/^0+//;
    $num += 0;
    my $group = int($num / 100);
    my $dir   = "$rfcstore/rfcs${group}00";
    my $leaf  = sprintf "RFC%04d.txt", $num;
    return "$dir/$leaf";
}

sub rfcindex_read
{
    my $filename = "$rfcstore/rfc-index-simple.xml";

    my $text    = read_file($filename);
    my @entries = ($text =~ m!<rfc-entry>(.*?)</rfc-entry>!gsm);
    for my $entry (@entries)
    {
        &rfcindex_entry($entry);
    }
}

sub rfcindex_extract_refs
{
    my ($entry, $refname) = @_;
    my @list;
    my @refs = ($entry =~ m!<$refname>(.*?)</$refname>!msg);
    for my $inner (@refs)
    {
        my @docs = ($inner =~ m!<doc-id>(.*?)</doc-id>!g);
        push @list, @docs;
    }
    if (scalar(@list))
    {
        return join ", ", @list;
    }
    else
    {
        return undef;
    }
}

sub rfcindex_entry
{
    # Parse an entry. They look like this :
    #        <doc-id>RFC7075</doc-id>
    #        <title>Realm-Based Redirection In Diameter</title>
    #        <author>
    #            <name>T. Tsou</name>
    #        </author>
    #        <author>
    #            <name>R. Hao</name>
    #        </author>
    #        <author>
    #            <name>T. Taylor</name>
    #            <title>Editor</title>
    #        </author>
    #        <date>
    #            <month>November</month>
    #            <year>2013</year>
    #        </date>
    #        <format>
    #            <file-format>ASCII</file-format>
    #            <file-format>HTML</file-format>
    #        </format>
    #        <page-count>10</page-count>
    #        <keywords>
    #            <kw>Diameter</kw>
    #            <kw>routing</kw>
    #        </keywords>
    #        <abstract>HTML-like-text</abstract>
    #        <draft>draft-ietf-dime-realm-based-redirect-13</draft>
    #        <obsoletes>
    #            <doc-id>RFC2271</doc-id>
    #        </obsoletes>
    #        <obsoleted-by>
    #            <doc-id>RFC3410</doc-id>
    #        </obsoleted-by>
    #        <updates>
    #            <doc-id>RFC6733</doc-id>
    #        </updates>
    #        <current-status>PROPOSED STANDARD</current-status>
    #        <publication-status>PROPOSED STANDARD</publication-status>
    #        <stream>IETF</stream>
    #        <area>ops</area>
    #        <wg_acronym>dime</wg_acronym>
    #        <doi>10.17487/RFC7075</doi>

    local ($entry) = @_;

    my ($num) = ($entry =~ /<doc-id>RFC(\d+)/);
    $num = 0 + $num;

    $file   = rfcfile($num);
    $format = 'TXT';
    $len    = -s $file // 'unknown';

    $status = 'UNKNOWN';
    if ($entry =~ m!<current-status>(.*?)</current-status>!) { $status = $1; }

    $obsoletes = rfcindex_extract_refs($entry, 'obsoletes');
    $obsoleted = rfcindex_extract_refs($entry, 'obsoleted-by');
    $updates = rfcindex_extract_refs($entry, 'updates');
    $updated = rfcindex_extract_refs($entry, 'updated-by');
    $also = rfcindex_extract_refs($entry, 'is-also');

    my $day = undef;
    if ($entry =~ m!<day>(.*?)</day>!) { $day = $1; }

    my $month = undef;
    if ($entry =~ m!<month>(.*?)</month>!) { $month = $1; }

    my $year = undef;
    if ($entry =~ m!<year>(.*?)</year>!) { $year = $1; }

    if (defined $day)
    {
        $date = "$day $month $year";
    }
    else
    {
        $date = "$month $year";
    }

    $authors = "";
    while ($entry =~ s/<author>\s*<name>(.*?)</name>/)
    {
        $authors .= $1 . " ";
    }
    $authors =~ s/ $//;

    $title = "RFC $num";
    if ($entry =~ m!<title>(.*?)</title>!) { $title = $1; }

    $abstract = undef;
    if ($entry =~ m!<abstract>(.*?)</abstract>!m)
    {
        $abstract = $1;
        $abstract =~ s/(<p>|<\/p>)/\n/g;
        $abstract =~ s/^\n//g;
        $abstract =~ s/\n$//g;
    }

    $rfc_format{$num}    = $format;
    $rfc_length{$num}    = $len;
    $rfc_status{$num}    = $status;
    $rfc_obsoletes{$num} = $obsoletes;
    $rfc_obsoleted{$num} = $obsoleted;
    $rfc_updates{$num}   = $updates;
    $rfc_updated{$num}   = $updated;
    $rfc_also{$num}      = $also;
    $rfc_date{$num}      = $date;
    $rfc_authors{$num}   = $authors;
    $rfc_title{$num}     = $title;
    $rfc_abstract{$num}  = $abstract;

    #print "$num\t$date\t$title\n";
}

1;
