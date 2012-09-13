#!/usr/bin/env perl
# -*- cperl -*-
=head1 NAME

texWordCount.cgi

=head1 SYNOPSIS

Perl script for CGI invocation of texWordCount.pl

=head1 DESCRIPTION

=head1 HISTORY

 ORIGIN: created from templateApp.pl version 3.4 by Min-Yen Kan <kanmy@comp.nus.edu.sg>

=cut
require 5.0;
use Getopt::Std;
use CGI;

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; }                 # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "1.0";
my $baseDir = "/home/min/public_html/texWordCount";
my $logFile = "$baseDir/cgiLog.txt";
my $seed = $$;
my $debug = 0;

my $loadThreshold = 0.5;
### END user customizable section

$| = 1;								    # flush output

### Ctrl-C handler
sub quitHandler {
  print STDERR "\n# $progname fatal\t\tReceived a 'SIGINT'\n# $progname - exiting cleanly\n";
  exit;
}

### HELP Sub-procedure
sub Help {
  print STDERR "usage: $progname -h\t\t\t\t[invokes help]\n";
  print STDERR "       $progname -v\t\t\t\t[invokes version]\n";
  print STDERR "       $progname [-q] filename(s)...\n";
  print STDERR "Options:\n";
  print STDERR "\t-q\tQuiet Mode (don't echo license)\n";
  print STDERR "\n";
  print STDERR "Will accept input on STDIN as a single file.\n";
  print STDERR "\n";
}

### VERSION Sub-procedure
sub Version {
  if (system ("perldoc $0")) {
    die "Need \"perldoc\" in PATH to print version information";
  }
  exit;
}

sub License {
  print STDERR "# Copyright 2004 \251 by Min-Yen Kan\n";
}

my $q = new CGI;
print "Content-Type: text/html\n\n";
print <<END;
<HTML><HEAD><TITLE>TexWordCount Demonstration</TITLE>
<LINK REL="stylesheet" type="text/css" href="npic.css" />
END
print "</HEAD><BODY>";

###
### MAIN program
###

my $input = $q->param('input');
my $file = $q->param('file');

if (loadTooHigh()) {
 printLoadTooHigh();
  exit;
}

if ($input eq "" && $file eq "") { # test to check form has input
  print "You must input some data.  <A HREF=\"index.html\">Start over.</A>\n";
  exit;
}

open (LOGFILE, ">>$logFile") || die "# $progname fatal\t\tCouldn't open logfile file \"$logFile\"";

if ($file eq "" && $input ne "") { # Input style #1, textarea
  print "Using input mode <B>Text Area</B>!\n";

  print LOGFILE "# Executed for REMOTE_ADDR " . $q->remote_addr() . " at " . localtime(time) . " via textarea\n";
  print LOGFILE "$input\n";
  open (OF,">$tmpfile") || die "# $progname fatal\t\tCan't open \"$tmpfile\" for temporary output!\n";
  print OF $input;
  close OF;
} else { # Input style #2, file upload 
  print "Using input mode <B>File Upload</B> for file named: $file!\n";
  
  print LOGFILE "# Executed for REMOTE_ADDR " . $q->remote_addr() . " at " . localtime(time) . " via file upload with filename $file\n";
  open (OF,">$tmpfile") || die "# $progname fatal\t\tCan't open \"$tmpfile\" for temporary output!\n";
  my $buffer = "";
  while (my $bytesread = read($file,$buffer,1024)) {
    print OF $buffer;
  }
  close OF;
}
close (LOGFILE);

# run command
print "<H2>Execution Progress</H2>";
print "[ <a href=\"index.html\">Back to texWordCount page</a> ]<BR/>";

$buf = "$baseDir/texWordCount.pl $tmpfile|";
print `date` . " [1] $buf";
open (IF, $buf);
print "<pre>";
print <IF>;
print "</pre>";
close IF;

print "<HR><H5>Generated on " . localtime(time) . " for a user at IP address " . $q->remote_addr() . " </H5>";

# remove temporary files
`rm -f $tmpfile`;

###
### END of main program
###

sub loadTooHigh {
my $load = `uptime`;
  $load =~ /load average: ([\d.]+)/i;
  my $load = $1;
  print "Load on server: $load<br/>";
  if ($load > $loadThreshold) { return 1; } else { return 0; }
}

sub printLoadTooHigh {
  print <<END;
<P>Sorry, the load on this machine is currently too high.  Public demos are only run when computing load is available.  <A HREF="index.html">Please try back again later</A>.  Thanks!
END
}
