#! /usr/bin/perl

# Construct the core StrongHelp pages about each RFC from the information
# read from files and the index

$datatype=",ffd"; # type to make it come out as data on RISC OS

mkdir "sh", 0755;
mkdir "sh/RFC", 0755;

# $lowest = 600; $highest = 1500;
$lowest = 1; $highest = 4500;
# $lowest = 300; $highest = 400;

require "rfcindex.pl";
require "rfcabstracts.pl";
require "groups.pl";
require "about.pl";
&init_groups();
&rfcindex_read();
&rfcabstracts_read($lowest,$highest);


# Set up the 'about' information for this manual
%about = (
  "Title" => "RFCs manual",
  "Description" => "This manual intends to provide a summary and quick reference for the Internet Request For Comments documents. " .
                   "It is not complete, nor (as with anything on the internet) can it ever be.",
  "Author" => "Justin Fletcher",
  "Email" => "gerph\@gerph.org",

  # Any entry with the form '#.## (## ### ####)' is a history entry
  "1.50 (01 Sep 1997)" => "First release to friends, and updated version to HENSA.\n" .
                          "RFCS down to 1750 documented by abstract, all RFCs up to 2062 have index entries.",
  "1.51 (28 Nov 1997)" => "Added very rudimentary Telnet option details.\n" .
                          "Reorganised 1-99 page to be in numerical rather than lexocographical order.",
  "2.00 (05 Sep 2003)" => "Re-write.\n" .
                          "The entire manual is now generated by a script (makerfcsh.pl) which processes the index and local copy of the RFCs.",
  "2.01 (09 Oct 2004)" => "Added a few new protocols and renamed them 'groups'.\n" .
                          "Because the RFCs manual is actually much larger than anticipated, it makes sense to bring together " .
                          "some areas that were not previously 'protocols', but document particular areas of interest.\n" .
                          "We now have sections for DHCP, IPP, LDAP, MIME, PPP and SNMP.\n" .
                          "New email address added.",
  "2.02 (18 Oct 2004)" => "Separated out the 'about' page generation, for use with both drafts and RFCs.\n" .
                          "Separated out the 'groups' generalisation, for use with both drafts and RFCs.\n" .
                          "Updated Abstract RFC identification to be a little more clever."
);

  
&create_indices();
&create_abstracts();
&create_groups();
&create_root();
&about_create("sh/about$datatype");

sub create_root
{
  open(TOP, "> sh/!Root$datatype") || die;
  local ($num,$x);
  print TOP <<EOM;
RFC index
#Parent StrongHelp:!Menu
#Table Columns 3
EOM
  $num=$lowest;
  while ($num < $highest)
  {
    if (defined($rfc_title{$num}) ||
        defined($rfc_title{$num+1}))
    {
      ($dir, $file) = &rfcnum_to_sh($num);
      $num-=$file;
      print TOP "<RFCs $num-".($num+99)."=>RFC$dir->\n";
    }
    $num+=100;
  }
  
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
  %months = (
    0 => "Jan",
    1 => "Feb",
    2 => "Mar",
    3 => "Apr",
    4 => "May",
    5 => "Jun",
    6 => "Jul",
    7 => "Aug",
    8 => "Sep",
    9 => "Oct",
    10 => "Nov",
    11 => "Dec"
  );
  $year+=1900;
  $today = "$mday $months{$mon} $year";
  
  print TOP <<EOM;
#EndTable

<Major groups=>Group_>
EOM
  print TOP &about_rootfooter("about", "makerfcs.pl");
  close(TOP);
}

sub create_groups
{
  local ($key);
  
  foreach $key (keys %group_title)
  {
    @list = @{$group_substrings{$key}};
    &create_groupinfo($key, $group_title{$key}, @list);
  }

  mkdir "sh/Group_",0755;
  open(INDEX, "> sh/Group_/!Root$datatype") || die;
  print INDEX <<EOM;
Major internet groups
#Parent !Root
#Prefix Group_
#Table Columns 3
EOM
  foreach $key (sort(keys %group_rfcs))
  {
    print INDEX "<$key> (${group_title{$key}})\n";
    &create_grouppage($key);
  }
  print INDEX "#EndTable\n";
}


sub create_grouppage
{
  local ($proto) = @_;
  local ($rfcs,$num);
  open(PROTO, ">  sh/Group_/$proto$datatype") || die;
  $rfcs = $group_rfcs{$proto};
  # print "$proto: $rfcs\n";
  print PROTO "Major groups - $proto (${group_title{$proto}})\n";
  print PROTO "#Parent Group_\n";
  while ($rfcs =~ s/^([0-9]*) //)
  {
    $num=$1;
    print PROTO &rfc_link($num)."\t".$rfc_title{$num}."\n";
  }
  close(PROTO);
}


sub create_indices()
{
  local ($num,$x);
  $num=$lowest;
  while ($num < $highest)
  {
    if (defined($rfc_title{$num}) ||
        defined($rfc_title{$num+1}))
    {
      ($dir, $file) = &rfcnum_to_sh($num);
      $basedir = "sh/RFC/$dir";
      mkdir "$basedir", 0755;
      $num-=$file;
      $x=0;
      # print "Creating index for $num\n";
      open(INDEX, "> $basedir/-$datatype") || die;
      print INDEX "RFCs by number ($num - ".($num+99).")\n";
      print INDEX "#Parent RFC\n";
      print INDEX "RFC\tDate\tTitle\n";
      print INDEX "#Line\n";
      while ($x < 100)
      {
        if (defined($rfc_title{$num+$x}))
        {
          print INDEX &rfc_link($num+$x)."\t${rfc_date{$num+$x}}\t${rfc_title{$num+$x}}\n";
        }
        $x++;
      }
    }
    $num+=100;
  }
}

sub create_abstracts
{
  local ($num);
  $num=$lowest;
  while ($num < $highest)
  {
    if (defined($rfc_title{$num}))
    {
      ($dir, $file) = &rfcnum_to_sh($num);
      $basedir = "sh/RFC/$dir";
      mkdir "$basedir", 0755;
      open(OUT, "> $basedir/$file") || die;
      print OUT "RFC$num\n";
      print OUT "#Parent $dir-\n";
      print OUT "Title:\t${rfc_title{$num}}\n";
      print OUT "Author(s):\t${rfc_authors{$num}}\n";
      print OUT "Status:\t${rfc_status{$num}}\n";
      print OUT "Date:\t${rfc_date{$num}}\n";
      print OUT "Length:\t${rfc_length{$num}}\n";
      if ($rfc_obsoletes{$num} ne "")
      { print OUT "Obsoletes:\t" . &rfc_refs($rfc_obsoletes{$num}) . "\n"; }
      if ($rfc_obsoleted{$num} ne "")
      { print OUT "Obsoleted by:\t" . &rfc_refs($rfc_obsoleted{$num}) . "\n"; }
      if ($rfc_updates{$num} ne "")
      { print OUT "Updates:\t" . &rfc_refs($rfc_updates{$num}) . "\n"; }
      if ($rfc_updated{$num} ne "")
      { print OUT "Updated by:\t" . &rfc_refs($rfc_updated{$num}) ."\n"; }
      if ($rfc_abstract{$num} ne "")
      {
        print OUT "#tab\n";
        print OUT "#line\n";
        print OUT &rfc_refs($rfc_abstract{$num}) . "\n";
      }
      close(OUT);
    }
    $num++;
  }
}

sub create_groupinfo
{
  local ($name, $desc, @find) = @_;
  local ($num, $x, $list);
  $num = $lowest;
  while ($num < $highest)
  {
    $title = $rfc_title{$num};
    if (defined($title))
    {
      $x=0;
      while ($x<= $#find)
      {
        $f = $find[$x];
        if ($f =~ s/^!//)
        { # Negated match
          if ($title=~/$f/)
          {
            $x=$#find;
          }
        }
        elsif ($title=~/$f/)
        {
          $list.="$num ";
          # $status = $rfc_status{$num};
          # print "$num: $x: $title [$status]\n";
          $x=$#find;
        }
        $x++;
      }
    }
    $num++;
  }
  $group_rfcs{$name} = $list;
  $group_title{$name} = $desc;
}

sub rfcnum_to_sh
{
  local ($num)=@_;
  local ($dir,$file);
  $file = $num % 100;
  if ($file<10)
  { $file="0$file"; }
  if ($num < 100)
  { $dir = "00"; }
  elsif ($num < 1000)
  { $dir = "0".($num - ($num % 100))/100; }
  else
  {
    $dir = ($num - ($num % 100))/100;
  }
  return ($dir,$file);
}

# generate the SH text for a link to an RFC
sub rfc_link
{
  local ($num)=@_;
  $num+=0;
  local ($dir,$file) = &rfcnum_to_sh($num);
  if ( defined($rfc_title{$num}) )
  {
    if ($num eq "$dir$file")
    {
      return "<RFC$num>";
    }
    else
    {
      return "<RFC$num=>RFC$dir$file>";
    }
  }
  else
  {
    return "RFC$num";
  }
}

sub rfc_refs
{
  local ($_)=@_;
  $_=&rfc_refs1($_);
  $_=&rfc_refs2($_);
  return $_;
}

sub rfc_refs1
{
  local ($_)=@_;
  local ($left,$right,$num);
  if (/RFC[ -]?\#?([0-9][0-9]+)/)
  {
    $left=$`;
    $right=$';
    $num=$1;
    # print "Matched $_ (".&rfc_link($num).")\n";
    return $left . &rfc_link($num) . &rfc_refs1($right);
  }
  return $_;
}

sub rfc_refs2
{
  local ($_)=@_;
  local ($left,$right,$num, $num2);

  # Be a little more clever about 'RFCs x and y'.
  if (/RFCs ?\#?([0-9][0-9]+) and \#?([0-9][0-9]+)/)
  {
    $left=$`;
    $right=$';
    $num=$1;
    $num2=$1;
    # print "Matched $_ (".&rfc_link($num).")\n";
    return $left . &rfc_link($num) . " and " . &rfc_link($num2) . &rfc_refs2($right);
  }
  
  return $_;
}
