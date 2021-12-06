#! /usr/bin/perl

$datatype=",ffd";

require "about.pl";
require "shtext.pl";

$shdir="shassign";
mkdir $shdir,0755;

&create_dhcpparameters();
&create_icmpparameters();
&create_urischemes();
&create_pppnumbers();

# Set up the 'about' information for this manual
%about = (
  "Title" => "Internet assignments manual",
  "Description" => "This manual intends to provide a summary and quick reference for the assignments made through ".
                   "IANA.".
                   "It is not complete, nor (as with anything on the Internet) can it ever be.",
  "Author" => "Justin Fletcher",
  "Email" => "gerph\@gerph.org",

  # Any entry with the form '#.## (## ### ####)' is a history entry
  "0.01 (11 Jun 2005)" => "Tentative implmentation, reading just a few of the many different assignment groups.",
);

&create_index();

&about_create("$shdir/about$datatype");

sub create_index
{
  open(ROOT, "> $shdir/!Root$datatype") || die "Failed to create !Root";
  print ROOT "Internet assignments\n";
  print ROOT "#Parent StrongHelp:!Menu\n";
  print ROOT "#Table Columns 3\n";
  for $file (sort { $index{$a} cmp $index{$b} } keys %index)
  {
    $rofile = $file;
    $rofile =~ s/\//./g;
    print ROOT "<${index{$file}}=>$rofile>\n";
  }
  print ROOT "#EndTable\n";
  print ROOT &about_rootfooter("about", "scanassign.pl");
  close(ROOT);
}

# Write a table ftorom an array of arrays (2D array)
sub write_table
{
  local (@table) = @_;
  local ($line, $str);
  local ($acc);
  $acc="";
  for ($line=0; $line<= $#table; $line++)
  {
    $str = join "\t", @{$table[$line]};
    while ($str =~ s/\t\t/\t \t/g) {}
    $acc.="$str\n";
    if ($line==0)
    { $acc.= "#line\n"; }
  }
  return $acc;
}

# Dump an array of arrays (2D array)
sub dump_table
{
  local (@table) = @_;
  local ($line);
  # Now step through each line, printing them all out
  for ($line=0; $line< $#table; $line++)
  {
    print "$line: ".(join "*", @{$table[$line]}) . "\n";
  }
}

# DHCP parameter list
sub create_dhcpparameters
{
  $index{'dhcp-parameters'} = "DHCP parameters";
  open(OUT, "> $shdir/dhcp-parameters$datatype") || die "Can't create DHCP parameters";
  print OUT "DHCP parameters\n";
  print OUT "#Parent !Root\n";
  
  # mkdir "$shdir/bootp",0755;
  
  open(IN, "< assignments/bootp-dhcp-parameters") || die "Can't read DHCP parameters";
  $acc = "";
  while (<IN>)
  {
    s/\r//;
    $acc .= $_;
  }
  $acc = &shtext_expand_tabs($acc);

  # First work on the section boundaries
  if ($acc =~ /BOOTP Vendor Extensions and DHCP Options are listed below:\n\n((.|\n)*?)\n\n/)
  {
    @table = &process_table($1);

    $table = &write_table(@table);
    $table = &shtext_replacerefs($table);
    print OUT $table;
  }
}

# ICMP parameters list
sub create_icmpparameters
{
  $index{'icmp-parameters'} = "ICMP parameters";
  open(OUT, "> $shdir/icmp-parameters$datatype") || die "Can't create ICMP parameters";
  print OUT "ICMP type parameter\n";
  print OUT "#Parent !Root\n";
  
  # mkdir "$shdir/bootp",0755;
  
  open(IN, "< assignments/icmp-parameters") || die "Can't read ICMP parameters";
  $acc = "";
  while (<IN>)
  {
    s/\r//;
    $acc .= $_;
  }
  $acc = &shtext_expand_tabs($acc);
  
  # First work on the section boundaries
  if ($acc =~ /are identified by a "type" field.\n\n((.|\n)*?)\n\n/)
  {
    @table = &process_table($1);
    
    $table = &write_table(@table);
    $table = &shtext_replacerefs($table);
    print OUT $table;
  }
}

# ICMP parameters list
sub create_urischemes
{
  $index{'uri-schemes'} = "URI schemes";
  open(OUT, "> $shdir/uri-schemes$datatype") || die "Can't create URI schemes";
  print OUT "URI schemes\n";
  print OUT "#Parent !Root\n";
  
  # mkdir "$shdir/bootp",0755;
  
  open(IN, "< assignments/uri-schemes") || die "Can't read URI schemes";
  $acc = "";
  while (<IN>)
  {
    s/\r//;
    $acc .= $_;
  }
  $acc = &shtext_expand_tabs($acc);
  
  # First work on the section boundaries
  if ($acc =~ /and access method.\n\n((.|\n)*?)Reserved URI Scheme Names/)
  {
    @table = &process_table($1);
    
    $table = &write_table(@table);
    $table = &shtext_replacerefs($table);
    print OUT $table;
  }
  
  # Now the 'Reserved URI scheme names'
  if ($acc =~ /Reserved URI Scheme Names:\n\n((.|\n)*?)\n\n\n/)
  {
    print OUT "\n#Line\nReserved URI scheme names\n";
    # Append the naming to the front
    $line = $1;
    $line = "Scheme Name      Description\n-----------      -----------------------------------------\n" . $line . "\n\n";
    # Strip leading spaces
    $line =~ s/\n   /\n/g;
    @table = &process_table($line);
    
    $table = &write_table(@table);
    $table = &shtext_replacerefs($table);
    print OUT $table;
  }
}

# PPP number lists
sub create_pppnumbers
{
  
  open(IN, "< assignments/ppp-numbers") || die "Can't read PPP numbers";
  $acc = "";
  while (<IN>)
  {
    s/\r//;
    $acc .= $_;
  }
  $acc = &shtext_expand_tabs($acc);
  
  # PPP protocol numbers
  $index{'ppp/protocols'} = "PPP protocols";
  mkdir "$shdir/ppp", 0755;
  open(OUT, "> $shdir/ppp/protocols$datatype") || die "Can't create PPP protocols";
  print OUT "PPP protocols\n";
  print OUT "#Parent !Root\n";
  if ($acc =~ s/Assigned PPP DLL Protocol Numbers\n\n((.|\n)*?)\n\n\n//)
  {
    $acc = $';
    @table = &process_table($1);
    
    $table = &write_table(@table);
    $table = &shtext_replacerefs($table);
    print OUT $table;
  }
 
  # Tidy up so that the sections can be spotted better
  $acc =~ s/\n\n\nCCP Option/\n\nCCP Option/;
  $acc =~ s/\n\n( 129   )/\n$1/;

  while ($acc =~ s/\n\n(PPP [A-Z0-9\- ]*)\n\n+(.*?)\n\n+(.*?)\n\n/\n\n/s)
  {
    $title=$1;
    $para=$2;
    $content = $3;
    # print "$title\n*$para*\n==$content==\n\n";
    # print "$title\n";
    $file = "";
    if ($title eq "PPP LCP AND IPCP CODES")
    {
      $title="PPP LCP, IPCP, CCP codes";
      $file="ppp/lcp-codes";
      $content =~ s/\*/ /g;
      $content =~ s/\+/ /g;
    }
    elsif ($title eq "PPP LCP CONFIGURATION OPTION TYPES")
    {
      $title="PPP LCP options";
      $file="ppp/lcp-options";
    }
    elsif ($title eq "PPP ECP CONFIGURATION OPTION TYPES")
    {
      $title="PPP ECP options";
      $file="ppp/ecp-options";
    }
    elsif ($title eq "PPP AUTHENTICATION ALGORITHMS")
    {
      $title="PPP authentication algorithms";
      $file="ppp/auth-algorithms";
    }
    elsif ($title eq "PPP CCP CONFIGURATION OPTION TYPES")
    {
      $title="PPP CCP options";
      $file="ppp/ccp-options";
    }
    elsif ($title eq "PPP SDCP CONFIGURATION OPTIONS")
    {
      $title="PPP SDCP options";
      $file="ppp/sdcp-options";
    }
    elsif ($title eq "PPP LCP FCS-ALTERNATIVES")
    {
      $title="PPP LCP FCS-alternatives";
      $file="ppp/fcs-alternatives";
    }
    elsif ($title eq "PPP MULTILINK ENDPOINT DISCRIMINATOR CLASS")
    {
      $title="PPP multi-link endpoint discriminator class";
      $file="ppp/multilink-ep-class";
    }
    elsif ($title eq "PPP LCP CALLBACK OPERATION FIELDS")
    {
      $title="PPP callback operations";
      $file="ppp/callback-ops";
    }
    elsif ($title eq "PPP ATCP CONFIGURATION OPTION TYPES")
    {
      $title="PPP ATCP options";
      $file="ppp/atcp-options";
    }
    elsif ($title eq "PPP OSINLCP CONFIGURATION OPTION TYPES")
    {
      $title="PPP OSINLCP options";
      $file="ppp/osinclp-options";
    }
    elsif ($title eq "PPP BANYAN VINES CONFIGURATION OPTION TYPES")
    {
      $title="PPP BVCP options";
      $file="ppp/bvcp-options";
    }
    elsif ($title eq "PPP BRIDGING CONFIGURATION OPTION TYPES")
    {
      $title="PPP BCP options";
      $file="ppp/bcp-options";
    }
    elsif ($title eq "PPP BRIDGING MAC TYPES")
    {
      $title="PPP BCP MAC types";
      $file="ppp/bcp-macs";
    }
    elsif ($title eq "PPP BRIDGING SPANNING TREE")
    {
      $title="PPP BCP spanning tree options";
      $file="ppp/bcp-spanningtree";
    }
    elsif ($title eq "PPP IPCP CONFIGURATION OPTION TYPES")
    {
      $title="PPP IPCP options";
      $file="ppp/ipcp-options";
    }
    elsif ($title eq "PPP IPV6CP CONFIGURATION OPTIONS")
    {
      $title="PPP IPV6CP options";
      $file="ppp/ipv6cp-options";
    }

    if ($file ne "")
    {
      $index{$file} = $title;
      open(OUT, "> $shdir/$file$datatype") || die "Can't create '$title'";
      print OUT "$title\n";
      print OUT "#Parent !Root\n";
      if ($content =~ /^(-+ +-+ *)\n/m)
      {
        $divider = $1; $t = $divider . " " x (53-length($divider)) . "---------";
        $content =~ s/$divider/$t/;
        $content =~ /^(.*)\n/;
        $header = $1; $t = $header . " " x (53-length($header)) . "Reference";
        $content =~ s/$header/$t/;
      }
      else
      {
        $content = "Type      Configuration Option                        Reference\n".
                   "----      --------------------                        ---------\n".
                   $content;
      }
      
      @table = &process_table($content);
      
      $table = &write_table(@table);
      $table = &shtext_replacerefs($table);
      print OUT $table;
    }
    else
    {
      print "-- ignored\n";
    }
  }
}

sub splitcolumns
{
  local ($line, $cols, @pos) = @_;
  local (@colstr);
  
  @colstr=();
  for ($col = 1; $col < $cols; $col++)
  {
    $str = substr $line, $pos[$col], $pos[$col+1] - $pos[$col];
    $str =~ s/^ *(.*?) *$/$1/; # strip leading and trailing spaces
    # print "Col $col : '$str'\n";
    $colstr[$col] = $str;
  }
  
  # Look for continued sections
  for ($col = 1; $col < $cols; $col++)
  {
    # Brackets spanning 2 columns ()
    if ($colstr[$col]   =~ /\([^)]*$/ &&
        $colstr[$col+1] =~ /[^(]*\)/)
    {
      if ($colstr[$col] =~ /^(.*?)  +(.*\(.*)$/)
      { # there was a gap before the bracket, so probably it belongs with the second
        $colstr[$col] = $1;
        $colstr[$col+1] = $2 . " " . $colstr[$col+1];
      }
      else
      { # no gap, so belongs with first
        $colstr[$col] .= " " . $colstr[$col+1];
        $colstr[$col+1] = "";
      }
    }
    # Brackets spanning 2 columns []
    if ($colstr[$col]   =~ /\[[^\]]*$/ &&
        $colstr[$col+1] =~ /[^\[]*\]/)
    {
      if ($colstr[$col] =~ /^(.*?)  +(.*\[.*)$/)
      { # there was a gap before the bracket, so probably it belongs with the second
        $colstr[$col] = $1;
        $colstr[$col+1] = $2 . " " . $colstr[$col+1];
      }
      else
      { # no gap, so belongs with first
        $colstr[$col] .= " " . $colstr[$col+1];
        $colstr[$col+1] = "";
      }
    }
    # Brackets spanning 3 columns
    if ($colstr[$col]   =~ /\([^)]*$/ &&
        $colstr[$col+1] !~ /\)/ &&
        $colstr[$col+2] =~ /[^(]*\)/)
    {
      $colstr[$col] .= " " . $colstr[$col+1] . " " . $colstr[$col+2];
      $colstr[$col+1] = "";
      $colstr[$col+2] = "";
    }
    
    if (length($colstr[$col])   == $pos[$col+1] - $pos[$col] ||
        length($colstr[$col])-1 == $pos[$col+1] - $pos[$col])
    {
      # It may be a string that spans over the boundary
      if (substr($line, $pos[$col+1]-1, 2) ne "  " && # not spaces at break
          substr($line, $pos[$col+1], 2) ne "  " &&  # not spaces following
          $colstr[$col+1] =~ /  /)                   # is a break in follow
      {
        # if there is a space on the boundary then add one in
        if (substr($line, $pos[$col+1]-1, 2) =~ / /)
        { $colstr[$col] .= " "; }
        
        $colstr[$col+1] =~ s/^(.*?)  +//;
        $colstr[$col] .= $1;
      }
    }
  }
  return @colstr;
}

sub process_table
{
  local ($_) = @_;
  local (@pos);
  local ($cols,$col,$left);
  local ($match);
  local (@row,$rows);
  local (@colstr);
  if (!/\n( *-.*)\n/m)
  {
    die "'$_'\nCould not find headings in block?\n";
  }
  $match=$1;
  $left = $`;
  $_=$';

  # Find out how big each column is
  $match = " $match"; # add one space on the left to make easy match
  $pos[0]=-1;
  $col=1;
  while ($match =~ s/^(.*? +)-/-/)
  {
    $pos[$col] = $pos[$col-1] + length($1);
    # print "$col : ${pos[$col]}\n";
    $col ++;
  }
  $cols = $col;
  $pos[$cols] = 1000;

  $_ .= "\n"; # ensure there's at least a newline on the last line

  $rows = 1;
  foreach $line (split /\n/)
  {
    @colstr = &splitcolumns($line, $cols, @pos);

    # check whether this is a continuation line
    if ($colstr[1] eq "" && $rows != 0)
    {
      # print "Extending preceeding row\n";
      for ($col = 1; $col < $cols; $col++)
      {
        if ($colstr[$col] ne "" &&
            $row[$rows-1][$col] ne "")
        {
          $row[$rows-1][$col] .= " " . $colstr[$col];
        }
      }
    }
    else
    {
      $row[$rows++] = [ @colstr ];
    }
  }
  
  # Process the headings
  foreach $line (reverse split /\n/, $left)
  {
    if ($line !~ /^ *$/)
    {
      @colstr = &splitcolumns($line, $cols, @pos);
  
      # check whether this is a continuation line
      # print "Extending preceeding row (of header)\n";
      for ($col = 1; $col < $cols; $col++)
      {
        if ($colstr[$col] ne "")
        {
          if ($row[0][$col] eq "")
          { $row[0][$col] = $colstr[$col]; }
          else
          { $row[0][$col] = $colstr[$col] . " " . $row[0][$col]; }
        }
      }
    }
  }
  
  # now remove the redundant left column
  for ($line=0; $line<=$#row; $line++)
  {
    shift @{$row[$line]};
  }
  
  return @row;
}
