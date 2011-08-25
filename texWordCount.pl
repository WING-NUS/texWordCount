#!/usr/bin/perl -w
# -*- cperl -*-
=head1 NAME

texWordCount

=head1 SYNOPSYS

=head1 DESCRIPTION

Counts words in a LaTeX file

use the -u switch for updating word count in a file delimited with

% texWordCount - begin
% texWordCount - end

lines.

use the -i switch for chapters
=head1 HISTORY

 ORIGIN: created from templateApp.pl version 3.3 by Min-Yen Kan <min :: cs . columbia . edu>, <kanmy :: comp . nus . edu . sg>
 ORIGIN: modified by Sam Tygier <samtygier :: yahoo . co . uk> at http://www.tygier.co.uk/ on 12 Jan 2007 to add functionality for
 \input tags
 ORIGIN: modified by Sam Tygier <samtygier :: yahoo . co . uk> at http://www.tygier.co.uk/ on 10 May 2007 to add functionality for recursive \include tags
 ORIGIN: modified by Gregor Heinrich <gregor :: arbylon . net> at http://www.arbylon.net/ on 26 March 2008 to add handling of document classes with a chapter level (book, report)
 ORIGIN: modified by Martin Magnusson for running headers
 ORIGIN: modified by Edward Vigmond <vigmond :: ucalgary . ca> on 26 March 2009 for counting words in captions
 ORIGIN: modified by Michael Dayan <mdayan.research :: googlemail . com> on 4 June for bug fixes wrt to subsubsection counting
 ORIGIN: modified by Sam Tygier <samtygier :: yahoo . co . uk> at http://www.tygier.co.uk/ on 13 Aug 2011 to add functionality for breaking by non-breaking spaces (~)

 RCS:$Log: texWordCount,v $
 RCS:
 RCS:Revision 1.5  Thu Jan 15 21:22:00 SGT 2009 kanmy
 RCS:Merging Martin Magnusson's edits for running headers
 RCS:
 RCS:Revision 1.4  Thu Mar 27 14:17:28 SGT 2008 kanmy
 RCS:Merging Gregor's edits in for doc classes with chapter levels
 RCS:
 RCS:Revision 1.3  2007/05/10 08:53:13  kanmy
 RCS:Merging Sam's edits for handling recursive input.  See subprocedure for include_files
 RCS:
 RCS:Revision 1.2  2007/01/12 08:53:13  kanmy
 RCS:Sam Tygier's edits to handle input
 RCS:

=cut

require 5.0;
use Getopt::Std;
# use strict 'vars';
# use diagnostics;
no warnings; # from Sam Tygier

### USER customizable section
my $tmpfile .= $0; $tmpfile =~ s/[\.\/]//g;
$tmpfile .= $$ . time;
if ($tmpfile =~ /^([-\@\w.]+)$/) { $tmpfile = $1; }      # untaint tmpfile variable
$tmpfile = "/tmp/" . $tmpfile;
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "090326";
### END user customizable section

### Ctrl-C handler
sub quitHandler {
  print STDERR "\n# $progname fatal\t\tReceived a 'SIGINT'\n# $progname - exiting cleanly\n";
  exit;
}

### HELP Sub-procedure
sub Help {
  print STDERR "usage: $progname -h\t\t\t\t[invokes help]\n";
  print STDERR "       $progname -v\t\t\t\t[invokes version]\n";
  print STDERR "       $progname [-cduiq] filename(s)...\n";
  print STDERR "Options:\n";
  print STDERR "\t-c\tCount words in captions\n";
  print STDERR "\t-d\tDebug Mode\n";
  print STDERR "\t-i\tInclusive.  Don't search for \{document\} tags.  Good for \\includes\n";
  print STDERR "\t-q\tQuiet Mode (don't echo license)\n";
  print STDERR "\t-u\tUpdate word counts in file\n";
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
  print STDERR "# Copyright 2002, 2007, 2009 \251 by Min-Yen Kan; modified by Sam Tygier, 2007; by Gregor Heinrich, 2008; by Martin Magnusson, 2009; by Edward Vigmond, 2009\n";
}

###
### MAIN program
###

my $cmdLine = $0 . " " . join (" ", @ARGV);
if ($#ARGV == -1) {       # invoked with no arguments, possible error in execution? 
  print STDERR "# $progname info\t\tNo arguments detected, waiting for input on command line.\n";
  print STDERR "# $progname info\t\tIf you need help, stop this program and reinvoke with \"-h\".\n";
}

$SIG{'INT'} = 'quitHandler';
getopts ('cdhiquv');
# our ($opt_d, $opt_h, $opt_i, $opt_q, $opt_u, $opt_v);      # declare variables that are imported from Getopt::Std

# global variables - over multiple files
my $many = 0;
my $manySum = 0;

# use (!defined $opt_X) for options with arguments
if (!$opt_q) { License(); }		  # call License, if asked for
if ($opt_v) { Version(); exit(0); }	  # call Version, if asked for
if ($opt_h) { Help(); exit (0); }	     # call help, if asked for

if (!$opt_q) {
  print "# LaTeX word count file format $outputVersion produced by $progname\n";
  print "# run as \"$cmdLine\"\n";
  print "# format: \\t x level of detail, number of words \\t section name\n";
}

## standardize input stream (either STDIN on first arg on command line)
my $fh;
my $filename;
if ($filename = shift) {
  NEWFILE:
  if (!(-e $filename)) { die "# $progname crash\t\tFile \"$filename\" doesn't exist"; }
  open (IF, $filename) || die "# $progname crash\t\tCan't open \"$filename\"";
  $fh = "IF";
} else {
  $filename = "<STDIN>";
  $fh = "STDIN";
}

# gregh: added chapter structure at depth 0 (section levels move down)
# vigmond: added floatsum, floatlabel, numfloat variables for captions
## one file local variables
my $state = 0;				  # Finite State Machine state
if ($opt_i) { $state = 1; }
my (@cSum, @sSum, @ssSum, @sssSum);
my (@cNames, @sNames, @ssNames, @sssNames);
my $sum = 0;
my @index = (0,0,0,0);
my $depth = 0;					   # indentation depth
my $line = 0;
my @lines;
my @floatsum;
my @floatlabel;
my $numfloat = 0;
my ($twcBegin, $twcEnd);

# read whole document and any included or inputed files
# includes and inputs can only be one deep so no need for
# recursion.
# warning, does not check \includeonly
my @headdoc = <$fh>;
my @wholedoc = include_files(@headdoc);

# chapter 0 for all text before first (or without any) chapter
$index[0]++;

# vigmond - added state = 2 for comment environment
# vigmond - added state = 3 for float environment and counting the caption
# vigmond - added state = 4 for float environment and still counting the caption
foreach (@wholedoc) {
  $lines[$line] = $_;
  $line++;
  if (/^\#/) { next; }      # skip comments
  elsif (/^\s+$/) { next; }      # skip blank lines
  elsif (/^\% texWordCount \- begin$/) { $twcBegin = $line-1; }      # note twc begin
  elsif (/^\% texWordCount \- end$/) { $twcEnd = $line-1; }      # note twc end
  else {
    if (/^\\end\{document\}/) {
      $state = 0;
      if ($opt_d) { print "found end document - at word $sum, line $line\n"; }
    }
    if ($state == 2) {
      if (/^\\end\{comment\}/) {
	if ($opt_d) { print "found end comment - resuming at line $line\n";}
	$state = 1;
      }
      next;
    }
    if (/^\\begin\{comment\}/) {
      if ($opt_d) { print "found start comment - at word $sum, line $line\n"; }
      $state = 2;
      next;
    }
    if (/^\\begin\{figure\*?\}/) {
      if ($opt_d) { print "found start figure - at word $sum, line $line\n"; }
      if ($opt_c) {
          $state = 3;
      } else {
          $state = 0;
      }
    }
    if (/^\\begin\{table\*?\}/) {
      if ($opt_d) { print "found start table - at word $sum, line $line\n"; }
      if ($opt_c)  {
          $state = 3;
      } else {
          $state = 0;
      }
    }
    if (/^\\chapter\*?(\[.*\])?\{(.+)\}/) {
      if ($opt_d) { print "found chapter \"$2\" - at word $sum, line $line\n"; }
      $index[0]++;
      $cNames[$index[0]] = $2;
      $depth = 0;
      $index[1] = 0;
      $index[2] = 0;
      $index[3] = 0;
    }
    if (/^\\section\*?(\[.*\])?\{(.+)\}/) {
      if ($opt_d) { print "found section \"$2\" - at word $sum, line $line\n"; }
      if ($depth == 0) { $index[1] = 0; } else {$index[1]++; }
      $depth = 1;
      $sNames[$index[0]][$index[1]] = $2;
      $index[2] = 0;
      $index[3] = 0;
    }

    if (/^\\subsection\*?(\[.*\])?\{(.+)\}/) {
      if ($opt_d) { print "found subsection \"$2\" - at word $sum, line $line\n"; }
      if ($depth == 1) { $index[2] = 0; } else {$index[2]++;  }
      $depth = 2;
      $ssNames[$index[0]][$index[1]][$index[2]] = $2;
      $index[3] = 0; 
    }
    if (/^\\subsubsection\*?(\[.*\])?\{(.+)\}/) {
      if ($opt_d) { print "found subsubsection \"$2\" - at word $sum, line $line\n"; }
      if ($depth == 2) { $index[3] = 0; } else {$index[3]++; }
      $depth = 3;
      $sssNames[$index[0]][$index[1]][$index[2]][$index[3]] = $2;
    }

    if ($state == 1) {
      s/\\%//g;      # escape \%
      s/%.+//g;      # rid comments
      s/\{/\{ /g;
      s/\}/ \}/g;

      my @words = split (/[\s~]+/, $_);      # split into words
      for (my $i = 0; $i <= $#words; $i++) {
	my $w = $words[$i];

	if ($w =~ /^\{\\/) { next; }      # rule out environment starts
	if ($w =~ /^\\/) { next; }
	if ($w !~ /\w/) { next; }

	#print $w, " ";
	$cSum[$index[0]]++;
	if ($depth >= 1) {
	    $sSum[$index[0]][$index[1]]++;
	  }
	if ($depth >= 2) {
	    $ssSum[$index[0]][$index[1]][$index[2]]++;
	  }
	if ($depth >= 3) {
	    $sssSum[$index[0]][$index[1]][$index[2]][$index[3]]++;
	  }
	$sum++;
      }
    }

    # start - added by Edward Vigmond Thu Mar 26 22:23:52 SGT 2009
    if ($state == 4) {		# in the middle of a multiline caption
        if (/\\label\{([^\}]+)\}/) { # the label command can be inside the caption
            $floatlabel[$numfloat] = $1;
            s/\\label\{$1\}//;
        }
        if (/(.+)\}/) {			 #find enclosing brace
            $state = 3;
            @words = split(/ +/, $1);
        } else {                        # the caption continues on another line
            @words = split(/ +/, $_);
        }
        $floatsum[$numfloat] += @words;
    }

    if ($state == 3) {				      # inside a float
        if (/\\label\{([^\}]+)\}/) {
            $floatlabel[$numfloat] = $1;
            s/\\label\{$1\}//;
        }
        if (/\\caption(\[.*\])?\{(.+)\}/) {	    # complete caption
            $state = 3;
        } elsif (/\\caption(\[.*\])?\{(.*)/) {   # multiline caption
            $state = 4;
        }
        my @words = split(/ +/, $2 );
        $floatsum[$numfloat] += @words;
    }
    # end - added by Edward Vigmond Thu Mar 26 22:23:52 SGT 2009

    if (/\\end\{figure\*?\}/) {
      if ($opt_d) { print "found end figure - resuming at line $line\n"; }
      $sum += $floatsum[$numfloat];	 # modified by Edward Vigmond
      $numfloat++;
      $state = 1;
    }
    if (/\\end\{table\*?\}/) {
      if ($opt_d) { print "found end table - resuming at line $line\n"; }
      $sum += $floatsum[$numfloat];	 # modified by Edward Vigmond
      $numfloat++;
      $state = 1;
    }
    if (/^\\begin\{document\}/) {
      if ($opt_d) { print "found start document - starting count at line $line\n"; }
      @index = (0,0,0,0);
      $depth = 0;
      $state = 1;
    }
  }
}
close ($fh);

# prepare output
my $buf = "";
$buf .= "$sum\twhole - $filename\n";

my $tab = "";
my $i = 0;
while (defined $cSum[$i]) {
  # if any chapter mark found
  if ($#cSum > 0) {
    if ($i == 0) {
      $buf .= "\t$cSum[$i]\t(Before Chapter 1)\n";
      $tab = "\t";    
    } else {
      $buf .= "\t$cSum[$i]\tChapter " .  ($i) . " - $cNames[$i] \n";    
    }
  }
  my $j = 0;
  while (defined $sSum[$i][$j]) {
    $buf .= "$tab\t$sSum[$i][$j]\tSection " . ($j+1) . " - $sNames[$i][$j] \n";
    my $k = 0;
    while (defined $ssSum[$i][$j][$k]) {
      $buf .= "$tab\t\t$ssSum[$i][$j][$k]\tSubsection " . ($k+1) . " - $ssNames[$i][$j][$k] \n";      
      my $ell = 0;
      while (defined $sssSum[$i][$j][$k][$ell]) {
        $buf .= "$tab\t\t\t$sssSum[$i][$j][$k][$ell]\tSubsubsection " . ($k+1) . " - $sssNames[$i][$j][$k][$ell] \n";
        $ell++;
      }
      $k++;
    }
    $j++;
  }
  $i++;
}

# start - added by Edward Vigmond Thu Mar 26 22:23:52 SGT 2009
$i = 0;
while (defined $floatsum[$i]) {
    $buf .= "\t$floatsum[$i]\tFloat ".($i+1)." - $floatlabel[$i] \n";
    $i++;
}
# end - added by Edward Vigmond Thu Mar 26 22:23:52 SGT 2009

print $buf;

if (defined $twcBegin &&
    defined $twcEnd &&
    $opt_u) {
  # untaint $filename variable
  if ($filename =~ /^([-\@\w.]+)$/) {
    $filename = $1;                     # $filename now untainted
  } else {
    die "# $progname fatal\t\tTainted data in \"$filename\"";        # log this somewhere
  }

  open (OF, ">$filename") || die "# $progname fatal\t\tcan't rewrite word count section\n";
  for (my $i = 0; $i < $twcBegin; $i++) {
    print OF $lines[$i];
  }
  my @bufLines = split (/\n/,$buf);
  print OF "% texWordCount - begin\n";
  print OF "% generated on " . localtime(time()) . "\n";
  print OF "% command was \"$cmdLine\"\n";
  for (my $k = 0; $k <= $#bufLines; $k++) {
    print OF "% ", $bufLines[$k], "\n";
  }
  print OF "% texWordCount - end\n";
  for (my $i = $twcEnd+1; $i < $#lines; $i++) {
    print OF $lines[$i];
  }
  close (OF);
}

if ($filename = shift) {
  $many = 1;
  $manySum += $sum;

  undef @cSum;
  undef @sSum;
  undef @ssSum;
  undef @sssSum;
  undef @cNames;
  undef @sNames;
  undef @ssNames;
  undef @sssNames;
  undef @floatlabel; # added by Edward Vigmond Thu Mar 26 22:23:52 SGT 2009
  undef @floatsum; # added by Edward Vigmond Thu Mar 26 22:23:52 SGT 2009
  undef @lines;

  goto NEWFILE;
}

if ($many == 1) {
  $manySum += $sum;
  print "$manySum\tall\n";
}

###
### END of main program
###

# From Sam Tygier (10 May 2007)
sub include_files{
   my @part_doc = ();
   my @whole_doc = ();
   push(@part_doc, @_);

   foreach (@part_doc) {
     if (/^\\(input|include){([^}]*)}/) {
           open (INPUT, $2.".tex") || die "# $progname crash\t\tCan't
open \"$2\"";
           my @sub_doc = <INPUT>;
           push(@whole_doc, include_files(@sub_doc));
	 } else {
           push(@whole_doc, $_);
	 }
   }
   return @whole_doc;
 }



