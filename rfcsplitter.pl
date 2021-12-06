#! /usr/bin/perl
# rfcsplitter - split the RFCs into mini directories
chdir "rfcs";
use integer;
print "Linking RFCs\n";
while (<*>)
{
  if (/rfc([0-9]*)\.txt/)
  {
    $num=$1+0;
    # print "Linking RFC $num\n";
    $dir=($num / 100) * 100;
    mkdir "../rfcsplit/$dir",0755;
    $from="../rfcsplit/$dir/rfc$num.txt";
    unlink $from;
    system "ln -s ../../rfcs/$_ $from";
  }
}
unlink "../rfcsplit/index.txt";
system "ln -s ../rfcs/index.txt ../rfcsplit/index.txt";
