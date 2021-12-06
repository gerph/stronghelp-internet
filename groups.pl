#! /usr/bin/perl
#
# Groups we use for both the drafts and RFC scanning scripts
# &init_groupinfo("Acronym", "Description", ..list of words to look for.. )
#   the word may be prefixed by ! to indicate that it is a negated match
#

sub init_groups
{
  local ($key);
  &init_groupinfo("DHCP", "Dynamic address allocation",
                  "DHCP",
                  "Dynamic Host Config");
  
  &init_groupinfo("DNS", "Name server",
                  "Domain Name",
                  "DNS");
  
  &init_groupinfo("Finger", "User information",
                  "Finger");
  
  &init_groupinfo("FTP", "File transfer",
                  "!TFTP",
                  "!Trivial",
                  "!Background",
                  "!Simple File Transfer",
                  "File Transfer Protocol",
                  "FTP");
  
  &init_groupinfo("HTTP", "Web page fetching",
                  "Hypertext Transfer Protocol",
                  "HTTP");

  &init_groupinfo("IMAP", "Email storage",
                  "IMAP",
                  "Internet Message Access Protocol",
                  "INTERNET MESSAGE ACCESS PROTOCOL");
  
  &init_groupinfo("IPP", "Network printing",
                  "Internet Printing Protocol",
                  "IPP",
                  "!HIPPI",
                  "!IPPM");

  &init_groupinfo("IRC", "Internet Relay Chat",
                  "Internet Relay Chat",
                  "IRC");
  
  &init_groupinfo("LDAP", "Distributed directories",
                  "Lightweight Directory Access Protocol",
                  "LDAP");
 
  &init_groupinfo("LPR", "Unix printing",
                  "Line printer");

  &init_groupinfo("MIME", "Mail attachment protocol",
                  "Multipurpose Internet Mail Extensions",
                  "MIME");
  
  &init_groupinfo("NFS", "Network File System",
                  "!WebNFS",
                  "NFS",
                  "Network File System");
  
  &init_groupinfo("NNTP", "Network news",
                  "Network News Transfer Protocol",
                  "NNTP",
                  "Usenet",
                  "USENET" );

  &init_groupinfo("POP", "Email storage",
                  "Post Office Protocol",
                  "POP");

  &init_groupinfo("PPP", "Internet transport",
                  "Point-to-Point protocol",
                  "PPP");
  
  &init_groupinfo("SMTP", "Email delivery",
                  "Simple Mail Transfer Protocol",
                  "SMTP",
                  "text messages",
                  "Internet Message Format");
  
  &init_groupinfo("SNMP", "Network management",
                  "Simple Network Management Protocol",
                  "SNMP");
  
  &init_groupinfo("Syslog", "Distributed event logging",
                  "Syslog");
  
  &init_groupinfo("Telnet", "Telnet",
                  "Telnet");
  
  &init_groupinfo("Time", "Time synchronisation",
                  "Time server",
                  "Time Protocol");
 
  &init_groupinfo("VPN", "Virtual Private Networking",
                  "Virtual Private");
}

sub init_groupinfo
{
  local ($name, $desc, @find) = @_;
  $group_title{$name} = $desc;
  @{$group_substrings{$name}} = @find;
}

1;
