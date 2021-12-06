#!/usr/bin/perl
# Process the drafts into a descriptive text

$datatype=",ffd"; # type to make it come out as data on RISC OS

require "groups.pl";
require "about.pl";
require "shtext.pl";
&init_groups();

chdir "drafts";
$shdir = "../shdraft";

# it is unwise to disable this - the pages become excessively large
$ignore_expired = 1;

# no guarentees on what happens if you disable this (not tested)
$ignore_error = 1;

# Promoted RFCs will be shown as links to the RFCs manual if disabled,
# or completely omitted if enabled
$ignore_promoted = 0;

# Set this to 1 to include the ENTIRE draft in the manual. This will
# cause you pain if you want to search the manual (!)
# The first time this was tried, the output was 112M, rather than around
# 2M.
$full_files = 0;

# Draft type constants
$draft_tfile = 0;               # A file exists, but its state is unknown
$draft_tactive = 10;            # It's 'alive'
$draft_tactive_nofile = 11;     # It's 'alive' (but not in the downloads)
$draft_texpired = 20;           # It's been deleted
$draft_texpiryimplied = 21;     # It's been deleted (implied by subsequent file existing)
$draft_tpromoted = 30;          # It's been promoted to an RFC
$draft_tpending = 40;           # It's not yet been processed by IESG
$draft_tpending_alsofile = 41;  # Processing, but actually exists (?!)
$draft_twithdrawn = 50;         # It's been withdrawn
$draft_treplaced = 60;          # Replaced by another draft
$draft_terror = -1;             # Don't understand it

# Set up the 'about' information for this manual
%about = (
  "Title" => "Internet Drafts manual",
  "Description" => "This manual intends to provide a summary and quick reference for the Internet Draft documents. " .
                   "It is not complete, nor (as with anything on the Internet) can it ever be.",
  "Author" => "Justin Fletcher",
  "Email" => "gerph\@gerph.org",

  # Any entry with the form '#.## (## ### ####)' is a history entry
  "0.01 (10 Oct 2004)" => "Initial version, just thrown together to make some sense of the drafts.",
  "0.02 (18 Oct 2004)" => "Massive updates to generalise the RFCs manual.\n".
                          "Added support for major groups, shared with RFCs.\n".
                          "Added support for 'about' page.\n".
                          "Updated Root page to be functional, rather than a placeholder.\n".
                          "Added index pages for authors.\n".
                          "Updated lists to sort all entries by dates.",
  "0.03 (20 Oct 2004)" => "Updated to use 'shtext' library to process the ".
                          "abstract text.\n" .
                          "Simple update to use 'shtext' to generate all ".
                          "the draft documents within the manual. This is ".
                          "huge, so will probably be left off for the ".
                          "foreseeable future.",
  "0.04 (30 May 2005)" => "Fixed to use new format of all_id.txt from source site\n"
);


&read_alldrafts();
&collate_authors();
&read_draftstate();
&read_draftabstracts();
&check_expired();
&check_abstracts();
&check_ignored();
&check_rfcs();

# Move anything that doesn't have a group into a group 'none' (which is
# already used by the abstracts document
foreach $dname (sort { $a cmp $b } keys %draft)
{
  if (!defined($draft_group{$dname}))
  { $draft_group{$dname} = "none"; }
}

# Now create the directory and start making some 'group' files
mkdir "$shdir", 0755;
mkdir "$shdir/group_", 0755;
mkdir "$shdir/author_", 0755;
mkdir "$shdir/Major_", 0755;
mkdir "$shdir/draft-", 0755;

&create_groups();
&create_drafts();
&create_authors();
&create_major();
&create_root();
if ($full_files)
{
  mkdir "$shdir/drafttext-", 0755;
  &create_fullfiles();
}
&about_create("$shdir/about$datatype");

sub read_alldrafts
{                    
  # First we locate the names of all the drafts
  while (<*>)
  {
    if ($_ =~ /^draft-/)
    {
      s/\.([A-Za-z]*)$//; # Lose the extension from everything
      $ext=$1;
      if (/-(\d\d)$/)
      {
        $version=$1;
        $draft{$_} = $draft_tfile;
        $draft_ext{$_}=$ext;
      }
      else
      { 
        print "Warning: $_ doesn't have a version\n";
        $draft{$_} = $draft_terror;
      }      
    }
  }
}

sub collate_authors
{
  # Flag a few authors as special
  $draftauthor_special{'ietf'} = 1; # not used as yet
  
  # Now let's see if we can collate all the author names
  $draft_unique_authors = 0;
  foreach $dname (sort { $a cmp $b } keys %draft)
  {
    if ($dname =~ /draft-([^-]+)-/)
    {
      $author = $1;
      if (!defined($draftauthor{$author}))
      { $draft_unique_authors++; }
      $draftauthor{$author} .= "$dname ";
    }
  }
  print "Unique authors: $draft_unique_authors\n";
}

sub read_draftstate
{
  open(ALL, "< all_id.txt") || die "Cannot read 'all_id'";
  while (<ALL>)
  {
    chomp;
    if (/^(draft-[^\t]*)\t+(\d\d\d\d-\d\d-\d\d)\t(.*)$/)
    {
      $dname=$1; $date=$2; $tail=$3;
      $draft_date{$dname} = $date;
      if ($tail =~ /processing/)
      {
        if (defined($draft{$dname}))
        {
          # print "Warning: $date $dname both 'Processing' and 'Active'\n";
          $draft{$dname}=$draft_tpending_alsofile;
        }
        else
        {
          $draft{$dname}=$draft_tpending;
        }
      }
      elsif ($tail =~ /Active/)
      {
        if (!defined($draft{$dname}))
        {
          # print "Warning: $date $dname 'Active' but not in directory\n";
          $draft{$dname}=$draft_tactive_nofile;
        }
        else
        {
          $draft{$dname}=$draft_tactive;
        }
      }
      elsif ($tail =~ /Expired/)
      {
        # Doesn't matter whether the file exists
        $draft{$dname}=$draft_texpired;
      }
      elsif ($tail =~ /RFC\t(.*)$/)
      {
        # Doesn't matter whether the file exists
        $draft{$dname}=$draft_tpromoted;
        $draft_rfc{$dname}=$1;
      }
      elsif ($tail =~ /Withdrawn/)
      {
        # Doesn't matter whether the file exists
        $draft{$dname}=$draft_twithdrawn;
      }
      elsif ($tail =~ /Replaced (replaced )?by (draft-.*)[\t]$/)
      {
        # Doesn't matter whether the file exists
        $d2=$1;
        $d2=~s/\.txt//;
        $draft{$dname}=$draft_treplaced;
        $draft_replacement{$dname}=$d2;
      }
      else
      {
        print "?? $tail\n";
      }
    }
    elsif (/^Internet-Drafts Status/ ||
           /^Web version/ ||
           /^http:\/\// ||
           /^$/)
    {
      # Ignore it; it's just one of the information lines
    }
    else
    {
      print "!! $_\n";
    }
  }
  
  foreach $dname (sort { $a cmp $b } keys %draft)
  {
    if ($draft{$dname} == $draft_tfile)
    {
      if ($dname =~ /^(.*)-(\d\d)$/ &&
          defined($draft{$1 . "-" . (sprintf "%02d", $2)}))
      {
        # print "Warning: $dname exists, but has implicitly expired\n";
        $draft{$dname} = $draft_texpiryimplied;
      }
      else
      {
        print "Warning: $dname exists, but its state is unknown\n";
        $draft{$dname} = $draft_terror;
      }
    }
  }
}

sub read_draftabstracts
{
  open(ABSTRACTS, "< 1id-abstracts.txt") || die "Cannot open abstracts\n";
  
  # Skip 6 lines which open things
  $dummy = <ABSTRACTS>;
  $dummy = <ABSTRACTS>;
  $dummy = <ABSTRACTS>;
  $dummy = <ABSTRACTS>;
  $dummy = <ABSTRACTS>;
  $dummy = <ABSTRACTS>;
  
  $insummary="";
  $inabstract="";
  while (<ABSTRACTS>)
  {
    chomp;
    if (/^([A-Z].*) \((.*)\)$/)
    {
      $draftgroup{$2} = $1;
      $ingroup = $2;
      # print "Group $2 known\n";
    }
    elsif (/^([A-Z].*)/)
    { # Catch any odd uses of the headings
      print "!! $_\n";
    }
    elsif (/^--*/)
    {
      # Ignore all headings
    }
    elsif (/^  (["[A-Za-z<1-9\(].*)$/)
    {
      if ($insummary ne "")
      { $insummary .= " $1"; }
      else
      { $insummary = "$1"; }
    }
    elsif (/^    ([A-Za-z\(].*)$/)
    {
      if ($inabstract ne "")
      { $inabstract .= "\n$1"; }
      else
      { $inabstract = "$1"; }
    }
    elsif (/^ *$/)
    {
      # Blank line
      if ($insummary ne "")
      {
        # if we're in a summary, we remember the title
        $summary=$insummary;
        $insummary = "";
      }
      elsif ($inabstract ne "")
      {
        # we've just ended an abstract so need to split summary up and
        # write details to the relevant draft
        if ($summary =~ /"(.*)", *(.*), *(\d*-...-\d\d), *<(.*)>/)
        {
          $title=$1;
          $authors=$2;
          $date=$3;
          $dname=$4;
          $dname=~ s/\.(.*)$//; # Lose the extension from everything
          $draft_title{$dname} = $title;
          $draft_authors{$dname} = $authors;
          $draft_abstract{$dname} = $inabstract;
          $draft_group{$dname} = $ingroup;
          # print "$dname => $ingroup\n";
          $inabstract = "";
        }
        else
        {
          print "!2! $summary\n";
        }
      }
    }
  }
}

sub check_expired
{
  # Skip all the files that exist and have not been marked as expired
  # and if they have the word 'deleted' or 'expired' at the top few lines
  # then flag them as expired.
  print "Skimming files for expiries\n";
  foreach $dname (keys %draft)
  {
    if ($draft{$dname} == $draft_tactive ||
        $draft{$dname} == $draft_tpending_alsofile)
    {
      $file = "$dname.txt"; # we assume it's text
      if (!open (DRAFT, "< $file"))
      {
        print "Warning: File $file isn't really there? (Expires)\n";
        $draft{$dname} = $draft_terror;
      }
      else
      {
        $str="";
        for ($lines=0; $lines<8; $lines++)
        {
          $str.=<DRAFT>;
        }
        if ($str =~ /deleted/i || $str =~ /expired/i)
        {
          # print "Flag expired: $dname\n";
          $draft{$dname} = $draft_texpired;
        }
      }
    }
  }
}

sub check_rfcs
{
  # Skim the files that are marked as being promoted to RFC status
  # so that we can get a title for them
  print "Skimming files for RFC titles\n";
  foreach $dname (keys %draft)
  {
    if ($draft{$dname} == $draft_tpromoted)
    {
      $file = "$dname.txt";
      if (!open (DRAFT, "< $file"))
      {
        # print "Warning: File $file isn't really there? (RFC)\n";
        # No need flag as an error; we just don't have a title
        # $draft{$dname} = $draft_terror;
        # Maybe we should look at the sh directory for the RFC itself ?
      }
      else
      {
        # print "Skimming $dname\n";
        $str="";
        for ($lines=0; $lines<8; $lines++)
        {
          $str.=<DRAFT>;
        }
        if ($str =~ /Title:(.*)\n *[^ ]*:/si)
        {
          $title=$1;
          $title=~ s/[\n\r]/ /g;
          $title=~ s/  +/ /g;
          $title=~ s/^ //g;
          $title=~ s/ $//g;
          # print "Update title: $dname : $title\n";
          $draft_title{$dname} = $title;
        }
      }
    }
  }
}

sub check_abstracts
{  
  foreach $dname (keys %draft)
  {
    if ($draft{$dname} == $draft_tactive ||
        $draft{$dname} == $draft_tactive_nofile ||
        $draft{$dname} == $draft_tpending ||
        $draft{$dname} == $draft_tpending_alsofile)
    {
      if (!defined($draft_abstract{$dname}))
      {
        print "Warning: $dname exists, but its abstract is unknown\n";
      }
    }
  }
}

sub check_ignored
{
  # Remove the expired entries if we want 
  if ($ignore_expired)
  {
    foreach $dname (keys %draft)
    {
      if ($draft{$dname} == $draft_texpired ||
          $draft{$dname} == $draft_texpiryimplied)
      { delete $draft{$dname}; }
    }  
  }
  # Same for those with errors
  if ($ignore_error)
  {
    foreach $dname (keys %draft)
    {
      if ($draft{$dname} == $draft_terror)
      { delete $draft{$dname}; }
    }  
  }
  # And for those which have been promoted
  if ($ignore_promoted)
  {
    foreach $dname (keys %draft)
    {
      if ($draft{$dname} == $draft_tpromoted)
      { delete $draft{$dname}; }
    }  
  }
}

sub create_groups
{
  print "Constructing group files\n";
  $file = "$shdir/!Groups$datatype";
  open(GROUPS, "> $file") || die "Can't create groups index $file";
  print GROUPS "Draft groups\n";
  print GROUPS "#Parent !Root\n";
  print GROUPS "#Prefix group_\n";
  print GROUPS "#table columns 4\n";
  foreach $group (sort { $a cmp $b } keys %draftgroup)
  {
    $file = "$shdir/group_/$group$datatype";
    open(GRP, "> $file") || die "Cannot write group file $file";
    print GRP "${draftgroup{$group}}\n";
    print GRP "#Parent !Groups\n";
    print GRP "#wrap off\n";
    $count=0;
    @array=();
    foreach $dname (keys %draft)
    {
      if ($draft_group{$dname} eq $group)
      {
        push @array, $dname;
      }
    }
    foreach $dname (sort { $draft_date{$a} cmp $draft_date{$b} } @array)
    {
      if ($draft_group{$dname} eq $group)
      { 
        $title = $draft_title{$dname};
        if ($title eq "") { $title=" "; }
        $date = $draft_date{$dname};
        if ($date eq "") { $date=" "; }
        print GRP "$date\t" . &draftstate($dname) . "\t" . &draftlink($dname) . "\t$title\n";
        $count++;
      }
    }
    if ($count > 0)
    {
      print GROUPS "<$group> ($count)\n";
    }
    close(GRP);
  }
  print GROUPS "#EndTable\n";
  close(GROUPS);
}


sub create_authors
{
  local ($file, $author, $dname, $list, $count, $title, $date);
  local ($fewlist, $array);
  print "Constructing authors files\n";
  $file = "$shdir/!Authors$datatype";
  open(AUTHORS, "> $file") || die "Can't create authors index $file";
  print AUTHORS "Draft authors\n";
  print AUTHORS "#Parent !Root\n";
  print AUTHORS "#Prefix author_\n";
  print AUTHORS "#fH4:Multiple drafts\n";
  print AUTHORS "#table columns 7\n";
  foreach $author (sort { $a cmp $b } keys %draftauthor)
  {
    $file = "$shdir/author_/$author$datatype";
    open(ATH, "> $file") || die "Cannot write author file $file";
    print ATH "Author $author\n";
    print ATH "#Parent !Authors\n";
    print ATH "#wrap off\n";
    $count=0;
    $list = $draftauthor{$author};
    @array = ();
    while ($list =~ s/^([^ ]*) //)
    {
      push @array, $1;
    }

    foreach $dname (sort { $draft_date{$a} cmp $draft_date{$b} } @array)
    {
      # have to check if it's defined because the entry might have been
      # removed by earlier operations
      if (defined($draft{$dname}))
      {
        $title = $draft_title{$dname};
        if ($title eq "") { $title=" "; }
        $date = $draft_date{$dname};
        if ($date eq "") { $date=" "; }
        print ATH "$date\t" . &draftstate($dname) . "\t" . &draftlink($dname) . "\t$title\n";
        $count++;
      }
    }
    if ($count > 1)
    {
      print AUTHORS "<$author> ($count)\n";
    }
    elsif ($count == 1)
    {
      $fewlist .= "<$author>\n";
    }
    close(ATH);
  }
  print AUTHORS "#EndTable\n";
  print AUTHORS "#fH4:Single drafts\n";
  print AUTHORS "#table columns 8\n";
  print AUTHORS "$fewlist";
  print AUTHORS "#EndTable\n";
  close(AUTHORS);
}

sub create_major
{ 
  # Create an index for the major groups
  local ($key);
  
  print "Creating Major groups data\n";
  
  foreach $key (keys %group_title)
  {
    @list = @{$group_substrings{$key}};
    # print "Major: $key: ".$#list." : ". (join ':', @list) ."\n";
    &create_majorinfo($key, $group_title{$key}, @list);
  }

  open(INDEX, "> $shdir/Major_/!Root$datatype") || die;
  print INDEX <<EOM;
Major internet groups
#Parent !Root
#Prefix Major_
#Table Columns 3
EOM
  foreach $key (sort keys %group_drafts)
  {
    print INDEX "<$key> (${group_title{$key}})\n";
    &create_majorpage($key);
  }
  print INDEX "#EndTable\n";
}

sub create_majorpage
{
  local ($proto) = @_;
  local ($drafts,$dname);
  local (@list);
  open(PROTO, "> $shdir/Major_/$proto$datatype") || die;
  $drafts = $group_drafts{$proto};
  # print "$proto: $rfcs\n";
  print PROTO "Major groups - $proto (${group_title{$proto}})\n";
  print PROTO "#Parent Major_\n";
  while ($drafts =~ s/^([^ ]*) //)
  {
    push @list, $1;
  }
  @list = sort { $b cmp $a } @list;
  while ($dname = pop @list)
  {
    $date = $draft_date{$dname};
    if ($date eq "") { $date=" "; }
    print PROTO $date."\t".&draftlink($dname)."\t".$draft_title{$dname}."\n";
  }
  close(PROTO);
}

sub create_majorinfo
{
  local ($name, $desc, @find) = @_;
  local ($draft, $x, $list);
  foreach $draft (keys %draft)
  {
    $title = $draft_title{$draft};
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
          $list.="$draft ";
          $x=$#find;
        }
        $x++;
      }
    }
  }
  $group_drafts{$name} = $list;
  $group_title{$name} = $desc;
}

sub create_drafts
{
  # Create all the draft files (!)
  print "Creating draft files\n";
  foreach $dname (keys %draft)
  {
    $dname =~ /^draft-([^-]*)-(.*)$/;
    if ($draft{$dname} == $draft_tpromoted)
    {
      # No point in creating draft pages for those that are promoted
      # as the links point directly to the RFC
    }
    else
    {
      mkdir "$shdir/draft-/$1-", 0755;
      $file="$shdir/draft-/$1-/$2";
      open(DRAFT, "> $file") || die "Can't write draft $file";
      print DRAFT "$dname\n";
      print DRAFT "#Parent !Root\n";
      print DRAFT "Name:\t$dname\n";
      print DRAFT "Title:\t${draft_title{$dname}}\n";
      print DRAFT "State:\t".&draftstate($dname)."\n";
      $authors=$draft_authors{$dname};
      if ($authors eq "") { $authors = "?"; }
      print DRAFT "Authors:\t$authors\n";
      $group=$draft_group{$dname};
      $groupname=$draftgroup{$group};
      print DRAFT "Group:\t<$groupname=>group_$group> ($group)\n";
      $date=$draft_date{$dname};
      if ($date eq "") { $date = "?"; }
      print DRAFT "Date:\t$date\n";

      # Special link just for the full files (!)
      if ($draft{$dname} != $draft_tpromoted &&
          -r "$dname.txt")
      {
        if ($full_files)
        {
          print DRAFT "Full text:\t<Local copy=>drafttext-$1-$2>\n";
        }
      }
      if ($draft_abstract{$dname} ne "")
      {
        print DRAFT "#line\n";
        print DRAFT "#wrap off\n";
        print DRAFT &shtext_process($draft_abstract{$dname})."\n";
      }
      close(DRAFT);
    }
  }
}

# ths is a REALLY nasty routine that creates a stronghelp page for every
# single one of the drafts. Icky (!)
sub create_fullfiles
{
  print "Creating full draft text files\n";
  # sort here isn't strictly necessary, but it helps to show how far
  # we are through the generation process.
  foreach $dname (sort { $a cmp $b } keys %draft)
  {
    $dname =~ /^draft-([^-]*)-(.*)$/;
    if ($draft{$dname} == $draft_tpromoted)
    {
      # No point in creating draft pages for those that are promoted
      # as the links point directly to the RFC
    }
    else
    {
      $first = $1; $second = $2;
      if (open(IN, "< $dname.txt"))
      {
        mkdir "$shdir/drafttext-/$first-", 0755;
        # if it's really a text file we process
        $text = "";
        print "SHText: $dname\n";
        while (<IN>)
        { $text .= $_; }
        &shtext_writefile("$shdir/drafttext-/$first-/$second",
                          $text, 
                          $draft_title{$dname},          # title
                          "draft-$first-$second",        # parent
                          "drafttext-$first-$second",    # self
                          1                              # auto-paginate
                          );
      }
    }
  }
}

sub create_root
{
  # Write out the root file
  print "Writing out root file\n";
  open(ROOT, "> $shdir/!Root$datatype") || die "Failed to create !Root";
  print ROOT "Internet Drafts\n";
  print ROOT "#Parent StrongHelp:!Menu\n";
  print ROOT "<By group=>!Groups>\t<By author=>!Authors>\n";
  print ROOT "<Major subjects=>Major_>\n";
  print ROOT &about_rootfooter("about", "scandrafts.pl");
  close(ROOT);
}

sub draftstate
{
  local ($dname)=@_;
  local ($state)=$draft{$dname};
  if (!defined($state)) { return "?Undefined?"; }
  if ($state == $draft_tfile) { return "?Exists?"; }
  if ($state == $draft_tactive) { return "Active"; }
  if ($state == $draft_tactive_nofile) { return "Active"; }
  if ($state == $draft_texpired) { return "Expired"; }
  if ($state == $draft_texpiryimplied) { return "ImpliedExpiry"; }
  if ($state == $draft_tpromoted) { return "RFC".$draft_rfc{$dname}; }
  if ($state == $draft_tpending) { return "Pending"; }
  if ($state == $draft_tpending_alsofile) { return "Pending"; }
  if ($state == $draft_twithdrawn) { return "Withdrawn"; }
  if ($state == $draft_treplaced) { return "Replaced"; }
  if ($state == $draft_terror) { return "Error"; }
  return "?Unknown?";
}

sub draftlink
{
  local ($dname)=@_;
  local ($haslink)=1;
  local ($str)="";
  if ($draft{$dname} == $draft_tactive ||
      $draft{$dname} == $draft_tactive_nofile ||
      $draft{$dname} == $draft_texpired ||
      $draft{$dname} == $draft_texpiryimplied ||
      $draft{$dname} == $draft_tpromoted ||
      $draft{$dname} == $draft_tpending ||
      $draft{$dname} == $draft_tpending_alsofile ||
      $draft{$dname} == $draft_treplaced)
  {
    $haslink = 1;
  }
  if ($haslink)
  { $str.= "<"; }
  $str.= "$dname";
  $str =~ s/draft-//;
  if ($draft{$dname} == $draft_tpromoted)
  { 
    local ($dir,$file) = &rfcnum_to_sh($draft_rfc{$dname});
    $str.= " (RFC)=>RFCs:RFC$dir$file>"; }
  elsif ($haslink)
  { $str.= "=>$dname>"; }
  return $str;
}

# Convert an RFC number to a StrongHelp filename number
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

