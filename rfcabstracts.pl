#! /usr/bin/perl


require "rfcindex.pl";

# Read all the RFC abstracts into the hash :
#   $rfc_abstract{<number>}

sub rfcabstracts_read
{
  local ($num, $end) = @_;
  local ($abstract);
  
  while ($num < $end)
  {
    print STDERR "Processing abstract in: $num\n";
    $abstract = &rfcabstract_readfile(rfcfile($num));
    if (defined($abstract))
    {
      $rfc_abstract{$num}=$abstract;
    }
    $num++; 
  }
  
  # Now deal with special cases
  $rfc_abstract{2691}=~s/\n* *MEMORANDUM OF UNDERSTANDING.*$//s;
  $rfc_abstract{1295}=~s/\n* *User Bill of Rights.*$//s;
  $rfc_abstract{1077}=~s/ *1.  Introduction and Summary.*$//s;
  $rfc_abstract{538}=~s/\n* *AAM\/jm.*$//s;
  $rfc_abstract{509}=~s/\n* *AAM\/jm.*$//s;
  $rfc_abstract{413}=~s/\n* *AAM\/jm.*$//s;
}

sub rfcabstract_readfile
{
  local ($file)=@_;
  local ($text,$ln);
  open(IN, "< $file") || return undef;
  $ln=0;
  while (($_=<IN>) && $ln < 300)
  {
    if (/^Abstract/i)
    {
      last;
    }
    $ln++;
  }
  if (/^Abstract/i)
  {
    $text="\n"; # ensure we start with a newline to make checking easier
    while (<IN>)
    {
      if ((/^[A-Za-z0-9]/ && !/Page [1-9]/ && !/^RFC [0-9]/) ||
          (/^ *Table Of Contents/i))
      {
        last;
      }
      elsif (/^[A-Za-z0-9]/ && /Page [1-9]/)
      {
        # ignore
      }
      elsif (/^RFC [0-9]/)
      {
        $_=<IN>; # Skip next line, regardless of content
      }
      else
      {
        s/^   //;
        $text.=$_;
      }
    }
  }
  
  # Remove any use of backspaces
  $text=~ s/(.)(\x08\1)+/$1/g;
  
  # In case any 'Table Of Contents' slipped through (especially for
  # RFC 2459
  $text=~ s/Table of contents.*//si;

  # Remove any underbars used
  $text=~ s/\n==+\n/\n\n/;
  $text=~ s/^==+\n/\n\n/;
  
  # Remove lots of newlines from the end of the string
  $text=~ s/\n\n*$/\n/s;
  
  # Condense page breaks
  while ($text=~ s/\n+\f\n+/\n\f/g)
  {
    # lots of replacement
  }
  $text=~ s/\f//g;
  
  # now lets check whether the text has been indented
  $text=~ s/\n +\n/\n\n/g; # ensure that blank lines never contain spaces
  $text.=" ";
  while ($text!~/\n[^ \n]/ && $text!~/^[\n ]*$/)
  {
    $text=~ s/\n /\n/g;
    $text.=" "; # ensure there's still a space at the end
  }
  $text=~ s/ *$//; # remove our trailing spaces
  
  # Strip leading and trailing newlines
  $text=~ s/^\n*//;
  $text=~ s/\n*$//;
  
  # Now join the lines together which can be joined
  $text=~ s/([^\n])\n([a-zA-Z0-9("].[^)])/$1 $2/g;
  $text=~ s/^\n([a-zA-Z0-9("].[^)])/ $1/g;
  
  return $text;
}

1;