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

sub rfcindex_read
{

  $rfc_specialtitle{49}=1;
  $rfc_specialtitle{270}=1;
  $rfc_specialtitle{1790}=1;
  $rfc_specialtitle{2429}=1;
  $rfc_specialtitle{2657}=1;
  
  open(INDEX, "rfcs/rfc-index.txt") || die;
  
  $sofar="";
  while (<INDEX>)
  {
    chomp;
    if ($_ eq "")
    {
      # blank line means end of this entry
      if (defined($num))
      {
        $sofar=~ s/  +/ /g;
        &rfcindex_entry($num,$sofar);
        $num=undef;
      }
    }
    elsif (/^([0-9]{4}) /)
    {
      $num=$1+0;
      $sofar=$';
    }
    else
    {
      $sofar.=$_;
    }
  }
  close(INDEX);
}

sub rfcindex_entry
{
  local ($num, $_)=@_;
  if (/Not online/i | /Not issued/i)
  {
    return;
  }
  if (s/\(Format: (..*)=(.*) bytes\)//)
  {
    $format=$1;
    $len=$2;
    if (s/\(Status: ([^)]*)\)//)
    {
      $status = $1;
      
      # Read the relationships
      $obsoletes = undef;
      $obsoleted = undef;
      if (s/\(Obsoletes ([^)]*)\)//)
      {
        $obsoletes=$1;
      }
      if (s/\(Obsoleted by ([^)]*)\)//)
      {
        $obsoleted=$1;
      }
      $updates = undef;
      $updated = undef;
      if (s/\(Updates ([^)]*)\)//)
      {
        $updates=$1;
      }
      if (s/\(Updated by ([^)]*)\)//)
      {
        $updated=$1;
      }
      $also = undef;
      if (s/\(Also ([^)]*)\)//)
      {
        $also=$1;
      }
      
      # Strip the trailing spaces
      s/ +$//;

      # Now see if we can get a date out
      if (s/\. ([0-9]*) ?([A-Z][a-z][a-z])[a-z]* ([12][09][0-9][0-9])\.$/./)
      {
        if ($1 eq "")
        {
          $date = "$2 $3";
        }
        else
        {
          $date = "$1 $2 $3";
        }
      }
      elsif (s/\. ([A-Z][a-z][a-z])[a-z]*-([0-9][0-9])-([12][09][0-9][0-9])\.$/./)
      {
        $date="$2 $1 $3";
      }
      
      # Strip off the authors from the end
      $authors=undef;
      if ($rfc_specialtitle{$num})
      {
        if (s/^(.*?\..*?)\. +(.*)$/$1/)
        {
          $authors = $2;
        }
      }
      elsif (s/^(.*?)\. +(.*)$/$1/)
      {
        $authors = $2;
      }
      if (!defined($authors))
      {
        # There are some RFCs that are just awkward in their use of
        # periods in their titles.
        print "Don't understand (authors): $num\n$_\n";
      }
      
      $rfc_format{$num} = $format;
      $rfc_length{$num} = $len;
      $rfc_status{$num} = $status;
      $rfc_obsoletes{$num} = $obsoletes;
      $rfc_obsoleted{$num} = $obsoleted;
      $rfc_updates{$num} = $updates;
      $rfc_updated{$num} = $updated;
      $rfc_also{$num} = $updated;
      $rfc_date{$num} = $date;
      $rfc_authors{$num} = $authors;
      $rfc_title{$num} = $_;
      # print "$num\t$date\n";
    }
    else
    {
      print "Don't understand (status): $num\n$_\n";
    }
  }
  else
  {
    print "Don't understand (format): $num\n$_\n";
  }
}

1;