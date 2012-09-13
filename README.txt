The most up-to-date documentation will be the web page (index.html).
This file just provided for reference.

--------------------------------------------------
File Listing and Description

cgiLog.txt	- log of cgi calls, should be omitted from the distribution.
index.html	- the web page, live at http://wing.comp.nus.edu.sg/~min/texWordCount.
inputExample/	- an example of \inputs through the main.tex file.  You can try running ../textWordCount.pl main.tex from within the directory
LICENSE.txt	- LPGL license text.
npic.css	- stylesheet used for index.html and CGI output.
README.txt	- this file.
test.tex	- sample single file .tex for testing.  Also see the inputExample/ files
texWordCount.cgi*	- the CGI backend, just for web-based demonstration
texWordCount.pl*	- the core file.  This is really the only file you'll need.  Requires perl.

--------------------------------------------------

               TexWordCount: a script to count words in LaTeX

   This is the home of TexWordCount.pl, a perl script to count words in
   TeX and LaTeX documents. It is free to be distributed and used (personal,
   commercial or otherwise) by anyone, licensed under the Lesser GNU Public
   License (LGPL).

 Thanks to...

   TexWordCount owes much of its added functionality and code to contributors
   which   are  incorporated  in  the  current  release.  Sam  Tygier  at
   http://www.tygier.co.uk/ added functionality for \input and recursive
   \include and more recently, for counting words with non-breaking spaces
   (LaTeX "~"). Gregor Heinrich at http://www.arbylon.net/ added handling of
   document classes with a chapter level (book, report). Martin Magnusson
   modified it for running headers. Edward Vigmond added proper counting words
   in captions. Michael Dayan corrected bug in subsubsection counting.

 Troubleshooting

   If you use the script and find problems with its execution, please report
   them to me. If you have any fixes that would be even better.

   Known bugs: Daniel Thomas reports that: "While using texWordCount.pl I
   noticed that using the -u option results in the file being word counted
   being modified in a rather dangerous manner likely to result in data loss if
   the  user does not have a backup. (among other things the \inputs were
   permanently input and the end of the file was cut off completely.)"

 Competitors

   A  more  comprehensive  version of word counting that has a UI is also
   available from: http://app.uio.no/ifi/texcount/index.html. You might want
   to try their tool out. Our tool is for fairly simple usage and for those
   environments that already have the prerequisites installed.

 Group Members

     * Min-Yen Kan - Developer

