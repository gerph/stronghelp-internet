#!/usr/bin/perl

$datatype = ",ffd";
$media = "media-types";
$sh = "shmedia";

push @INC, '.';

require "about.pl";
require "shtext.pl";

mkdir $sh, 0755;

# Set up the 'about' information for this manual
%about = (
  "Title" => "MIME Media Types",
  "Description" => "This manual intends to provide a quick reference " .
                   "to the registered MIME Media types. " .
                   "It is not complete, nor (as with anything on the Internet) can it ever be.",
  "Author" => "Charles Ferguson",
  "Email" => "gerph\@gerph.org",

  # Any entry with the form '#.## (## ### ####)' is a history entry
  "0.01 (19 Oct 2004)" => "Initial version, knocked up quickly.",
  "0.02 (20 Oct 2004)" => "Moved to using shtext library for processing of ".
                          "plain text segments of the media type files.",
  "0.03 (06 Dec 2021)" => "Updated to run on modern systems.\n",
);

# Scan the directories for new media types
&inittrees();
&initmajor();
&scanmajor();
&scanminor();
&create_root();
&create_majorindices();
&create_files();
&about_create("$sh/about$datatype");

sub inittrees
{
  $mime_tree{''}    = "General interest"; # the IETF tree
  $mime_tree{'vnd'} = "Commercial products (vnd.)"; # the vendor tree
  $mime_tree{'prs'} = "Non-commercial products (prs.)"; # the personal tree
  $mime_tree{'x'}   = "Experimental (x.)"; # the experimental tree
  $mime_tree{'zzz'} = "Miscellaneous"; # other, uncategorised types
}

sub initmajor
{
  $mime_major{'text'} = "Textual material";
  $mime_major{'image'} = "Graphical material";
  $mime_major{'audio'} = "Audio data";
  $mime_major{'video'} = "Time-varying-picture image";
  $mime_major{'application'} = "Discrete data for applications";
  $mime_major{'multipart'} = "Multiple data sets";
  $mime_major{'message'} = "Encapsulated message data";
  $mime_major{'model'} = "Behavioural or physical representation";
}

sub scanmajor
{
  while (<$media/*>)
  {
    /\/([^\/]*$)/;
    $major = $1;
    if (!defined($major))
    {
      $mime_major{$major} = "?Unknown?";
      print "Warning: Unknown major type '$major'\n";
    }
  }
}

sub scanminor
{
  # Look for files that exist
  foreach $major (keys %mime_major)
  {
    while (<$media/$major/*>)
    {
      /\/([^\/]*$)/;
      $minor = $1;
      if (!/index.*html/)
      {
        open(IN, "< $_") || die "File isn't really there";
        while (<IN>)
        {
          $mime_full{"$major/$minor"} .= $_;
        }
      }
    }
    
    # And for the types in the index.html which have no files
    if (open(INDEX, "< $media/$major/index.html"))
    {
      # we could open the file, so read and parse
      $all = "";
      while (<INDEX>)
      {
        s/[\r\n]//g;
        $all .= $_;
      }
      while ($all =~ s/<td><a>([^<]*)<\/a><\/td> *<td>\[<a href="([^"]*)">RFC ?([0-9]*)<\/a>//)
      {
        # print "RFC-based sub-type: $major/$1, $3\n";
        $minor = $1;
        $mime_full{"$major/$minor"} = "See RFC $3.\n";
      }
    }
  }
}

sub create_root
{
  open(ROOT, "> $sh/!Root$datatype") || die "Cannot write !Root\n";
  print ROOT "MIME Media Types\n";
  print ROOT "#Parent StrongHelp:!Menu\n";
  foreach $major (sort { $a cmp $b } keys %mime_major)
  {
    print ROOT "<$major>\t${mime_major{$major}}\n";
  }
  print ROOT &about_rootfooter("about", "scanmedia.pl");
  close(ROOT);
}

sub create_majorindices
{
  foreach $major (sort { $a cmp $b } keys %mime_major)
  {
    mkdir "$sh/$major", 0755;
    open(IND, "> $sh/$major/!Root$datatype") || die "Cannot write major index $major\n";

    print IND "$major - ${mime_major{$major}}\n";
    print IND "#Parent !Root\n";
    
    # Copy the subset-array so that it's easier to process
    undef %mime_minor;
    foreach $full (sort { $a cmp $b } keys %mime_full)
    {
      if ($full =~ /^$major\/(.*)$/)
      {
        # print "$major : $1\n";
        $mime_minor{$1} = $mime_full{$1};
      }
    }
    
    # Now process each of the trees individually
    foreach $tree (sort { $a cmp $b } keys %mime_tree)
    {
      $found = 0;
      foreach $minor (sort { $a cmp $b } keys %mime_minor)
      {
        if (($tree ne "" && $minor =~ /^$tree\./)||
            ($tree eq "" && $minor !~ /\./) ||
            $tree eq "ZZZ")
        {
          if ($found==0)
          {
            print IND "#fH4:${mime_tree{$tree}}\n";
            print IND "#table columns 5\n";
            $found=1;
          }
          $name = $minor;
          $name =~ s/^$tree\.//;
          print IND "<$name=>".&mime_helpname($major,$minor).">\n";
          delete $mime_minor{$minor};
        }
      }
      if ($found)
      { print IND "#endtable\n"; }
    }
  }  
}

sub mime_helpname
{
  local ($major,$minor) = @_;
  $minor =~ tr/.\//_-/;
  return "${major}_$minor";
}
sub mime_filename
{
  local ($major,$minor) = @_;
  $minor =~ tr/.\//_\//;
  return "${major}/_$minor$datatype";
}


sub create_files
{
  foreach $full (keys %mime_full)
  {
    $full =~ /^(.*?)\/(.*?)$/;
    $major = $1;
    $minor = $2;

    &shtext_writefile("$sh/".&mime_filename($major, $minor),
                      $mime_full{$full}, # the text of the file
                      $full, # the title
                      "!Root", # our parent
                      &mime_helpname($major, $minor), # ourselves
                      1 # paginate the document if necessary
                      );
  }
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

# generate the SH text for a link to an RFC
sub rfc_link
{
  local ($num)=@_;
  $num+=0;
  local ($dir,$file) = &rfcnum_to_sh($num);
  # JRF: Note that unlike the RFCs file, we don't check if we know the
  #      RFC but just link blindly to it; we're a separate manual so it
  #      makes more sense to reference them directly.
  return "<RFC$num=>RFCs:RFC$dir$file>";
}

# JRF: Note that this is the same function as in makerfcsh.pl
sub rfc_refs
{
  local ($_)=@_;
  local ($left,$right,$num);
  if (/RFC[- ]?\#?([0-9][0-9]+)/)
  {
    $left=$`;
    $right=$';
    $num=$1;
    # print "Matched $_ (".&rfc_link($num).")\n";
    return $left . &rfc_link($num) . &rfc_refs($right);
  }
  return $_;
}

sub expand_tabs
{
  local ($_)=@_;
  while (/\n([^\n]*)\t/)
  {
    $_ = "$`\n$1" . (" " x (8 - length($1) % 8)) . "$'";
  }
  return $_;
}
