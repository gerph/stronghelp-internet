#! /usr/bin/perl
#
# A StrongHelp paged text file processor, designed to also redirect
# certain types of links at known manuals.
#
# &shtext_writefile(outfilename, 
#                   string,
#                   title,
#                   parent,
#                   self,
#                   paginated);
# Converts a string into a file

# this is only for testing
if (0)
{
  $datatype = ",ffd";
  # open(IN, "rfcsplit/800/rfc822.txt") || die;
  # open(IN, "media-types/text/vnd.abc") || die;
  open(IN, "drafts/draft-ietf-zeroconf-ipv4-linklocal-17.txt") || die;
  while (<IN>)
  {
    $text .= $_;
  }
  
  &shtext_writefile("tst/!Root", $text, "RFC 822", "PARENT", "!Root", 1);
}

# shtext_process - process the string passed to make it safe
#                  for use with StrongHelp and to expand the references
#                  it contains, where appropriate.
sub shtext_process
{
  local ($text) = @_;
  $text =~ s/\r//g;
  $text =~ s/\\/\\\\/g;
  $text =~ s/</\\</g;
  $text =~ s/>/\\>/g;
  $text =~ s/{/\\{/g;
  $text =~ s/}/\\}/g;
  $text =~ s/\<#/\\#/mg;
  $text =~ s/\n[ \t]+\n/\n\n/gs;
  $text =~ s/^\n*//; # Trim leading newlines
  $text =~ s/\n~~~~~+\n/\n#Line\n/;
  $text =~ s/\n-----+\n/\n#Line\n/;

  # Trim trailing newlines, spaces and form feeds from end of file
  $text =~ s/[\n\f \t]*$//;
  
  $text = &shtext_expand_tabs($text);
  $text = &shtext_replacerefs($text);
  
  return $text;
}

sub shtext_writefile
{
  local ($file, $text, $title, $parent, $self, $paged) = @_;
  local ($top);

  # trim the data type if they left it on
  $file =~ s/$datatype$//;

  # let's tidy some lines up so that StrongHelp doesn't explode
  $text = &shtext_process($text);
  
  if ($paged && $text!~/\f/)
  {
    # they requested pagination, but there are no form feeds for
    # pagination in the base document. Count the number of linefeeds
    # in the document.
    @sp = split /\n/, $text;
    if ($#sp > 100)
    {
      # We reckon that the document should be split into smaller chunks.
      # Let's do so.
      
      # Decide if the document looks like an RFC, but with formfeeds expanded
      @temp = split /     \[Page [0-9]+\]\n\n\n\n+/, $text;
      if ($#temp > 4)
      {
        # more than 4, so probably it's a draft-like RFC
        $text =~ s/(     \[Page [0-9]+\])\n\n\n\n+/$1\n\f\n/gm;
        # Trim trailing newline, formfeed
        $text =~ s/[\n\f \t]$//;
      }
      else
      {
        # Doesn't look like an RFC, so just truncate regularly
        $text="";
        for ($line = 0; $line < $#sp; $line++)
        {
          $text .= $sp[$line] . "\n";
          if (($line % 58) == 57)
          {
            $text .= "\f";
          }
        }
        # Trim trailing newline, formfeed
        $text =~ s/[\n\f \t]$//;
      } 
    }
  }

  # let's Paginate at formfeeds if we can
  if ($paged && $text=~/\f/)
  {
    @pagetext = [];
    $page = 1;
    # JRF: Consider doing this as a split instead.
    while ($text =~ s/^([^\f]*)\f//)
    {
      $pagetext[$page++] = $1;
    }
    $pagetext[$page] = $text;
    # print "Read $page page(s)\n";
    mkdir "$file-", 0755;
    for ($page=1; $page <= $#pagetext; $page++)
    {
      if ($page == 1)
      { open(SHT, "> $file$datatype") || die "Could not write shtext $file\n";
        $pname=$parent;
      }
      else
      { open(SHT, "> $file-/$page$datatype") || die "Could not write shtext $file-$page\n";
        $pname=$self;
      }
      $text = $pagetext[$page];
      # We want to trim the page to reduce the number of 'common'
      # spaces on the left. This will make the file smaller, and
      # more importantly tidy up its rendering.
      $minspaces = length($text);
      foreach $line (split /\n/, $text)
      {
        if ($line ne "")
        {
          $line=~/^( *)/; # match the leading spaces
          if (length($1) < $minspaces)
          { $minspaces = length($1); }
        }
      }
      if ($minspaces > 0)
      {
        # remove those leading spaces
        $minspaces = " " x $minspaces;
        $text =~ s/^$minspaces//gm;
      }
      print SHT <<EOM;
$title (page $page)
#Parent $pname
#wrap off
#fCode
$text
EOM
      $more = "";
      if ($page == 2)
      { $more .= "<Previous page=>$self>  "; }
      elsif ($page > 2)
      { $more .= "<Previous page=>$self-".($page-1).">  "; }
      if ($page + 1 <= $#pagetext)
      { $more .= "<Next page=>$self-".($page+1).">  "; }
      if ($more ne "")
      {
        print SHT "#line\n#f\n#align centre\n  $more";
      }
      close(SHT);
    }
  }
  else
  {
    # Just lose the formfeeds
    $text =~ s/\f//g;
    open(SHT, "> $file$datatype") || die "Could not write shtext $file\n";
    print SHT <<EOM
$title
#Parent $parent
#wrap off
#fCode
$text
EOM
  }
}


# Convert an RFC number to a StrongHelp filename number
sub shtext_rfcnum_to_sh
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
sub shtext_rfclink
{
  local ($num)=@_;
  $num+=0;
  local ($dir,$file) = &shtext_rfcnum_to_sh($num);
  # JRF: Note that unlike the RFCs file, we don't check if we know the
  #      RFC but just link blindly to it; we're a separate manual so it
  #      makes more sense to reference them directly.
  return "<RFC $num=>RFCs:RFC$dir$file>";
}

# JRF: Note that this is the same function as in makerfcsh.pl
sub shtext_rfcrefs
{
  local ($_)=@_;
  local ($left,$right,$num);
  if (/RFC[- ]?\#?([0-9][0-9]+)/)
  {
    $left=$`;
    $right=$';
    $num=$1;
    # print "Matched $_ (".&rfc_link($num).")\n";
    return $left . &shtext_rfclink($num) . &shtext_rfcrefs($right);
  }
  return $_;
}

sub shtext_expand_tabs
{
  local ($_)=@_;
  while (/\n([^\n]*?)\t/)
  {
    $_ = "$`\n$1" . (" " x (8 - length($1) % 8)) . "$'";
  }
  return $_;
}

sub shtext_urlrefs
{
  local ($_)=@_;
  local ($left,$right,$url,$proto);
  # this is a really simple URL replacement routine - it's NOT complete
  # in particular it won't work on any protocol that isn't x://y/z
  if (/(([a-z]+):\/\/[A-Za-z0-9_\-\.]+\/[A-Za-z0-9\-\.\/_~]*(#[A-Za-z0-9_\-]*)?)/)
  {
    $left=$`;
    $right=$';
    $url=$1;
    $proto=$2;
    # print "Spotted $proto : $url\n";
    if ($proto eq "http" ||
        $proto eq "ftp" ||
        $proto eq "https")
    {
      return $left . "<$url=>#url>" . &shtext_urlrefs($right);
    }
    else
    {
      return $left . $url . &shtext_urlrefs($right);
    }
  }
  return $_;
}

sub shtext_replacerefs
{
  local ($text)=@_;
  $text = &shtext_rfcrefs($text);
  $text = &shtext_urlrefs($text);
  return $text;
}
1;
