#!/usr/bin/perl -w
# Public domain. Please report errors, patches, suggestions to 
# marco at angrynerds.com
# Some tests and initial variables
#

$filename = $ARGV[0] || die "Please pass a file.xml as argument\n\n";

-e $filename || die "$filename does not exists\n\n";
-T $filename || die "$filename doesn't look as a text file, exiting\n\n";
$outputfile = $filename ; 
$outputfile =~ s/\.xml/.tex/ ;
# print "Processing $filename, I'll output on $outputfile\n";
$TEXDIRECTORY=$ENV{TEXDIRECTORY};  
$PDFDIRECTORY=$ENV{PDFDIRECTORY};  
if (! $ENV{TEXDIRECTORY}) { $TEXDIRECTORY="LaTeX_archive"; }
if (! $ENV{PDFDIRECTORY}) { $PDFDIRECTORY="pdf_archive"; }
# print "output in $TEXDIRECTORY and $PDFDIRECTORY\n";
## read the file and put it in 3 array: @header, @body, @fnotes
open(IN, "< $filename")  || die "I cannot open $filename, why?\n\n";
while ($r = <IN>) {
	if ($r =~ m/^\s*<!--.*-->\s*$/) {
		push @header, $r;
	}
	elsif ($r =~ m/^\s*\[\d+\]\s*/) {
		$r =~ s/^\s*\[\d+\]\s*//;
		chop ($r);
		$r =~ s/\s*$//;
		push @fnotes, $r;
	}
	elsif ($r =~ m/^\s*<(h2|h3|h4|h5|strong)>\s*([Ff]oot)?[Nn]otes\s*<\/(h2|h3|h4|h5|strong)>\s*$/) {
		print "Building the footnotes...\n"
	}
	else {
		push @body, $r;
	}
}
close(IN);	
	
if (@fnotes) { $has_notes = 1 } else { $has_notes = 0 }

$no_header_warning = "Error! The file must contain a header with the following fields.\nOnly author and title are mandatory. If empty, skip the line.\nPlease don't break the lines.\n<!-- AUTHOR=\"The autor\" -->\n<!-- TITLE=\"The Title\" -->\n<!-- DATE=\"Date of the original publication\" -->\n<!-- TOPICS=\"Various topics, etc.\" -->\n<!-- ADC=\"the adc signature\" -->\n<!-- SOURCE=\"Retrieved on February 15th, 2009 from http://www.anarchistnews.org/?q=node/6451\" -->\n<!-- NOTES=\"Some notes\" -->" ;

# process the header and extract the fields
@header || die "$no_header_warning\n\n";
foreach $field_header (@header) {
	if ($field_header =~ m/<!--\s*AUTHOR="(.+)"\s*-->/) { 
		$AUTHOR=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*TITLE="(.+)"\s*-->/) { 
		$TITLE=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*DATE="(.+)"\s*-->/) { 
		$DATE=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*TOPICS="(.+)"\s*-->/) { 
		$TOPICS=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*ADC="(.+)"\s*-->/) { 
		$ADC=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*SOURCE="(.+)"\s*-->/) { 
		$SOURCE=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*NOTES="(.+)"\s*-->/) { 
		$NOTES=&clean_the_html($1);
	}
	elsif ($field_header =~ m/<!--\s*LATEXCODE="(.+)"\s*-->/) {
	       	$LATEXCODE=$1; }
}
if (! $LATEXCODE) {$LATEXCODE = ""}
	
# insert the footnotes
if ($has_notes == 1) {
	foreach $ln (@body) {
		while ($ln =~ m/\[\d{1,3}\]/) {
			$nota= shift @fnotes || die "Missing footnotes lines in $filename \n\n";
			$truenote="FooTNoTeSBeGiN$nota FooTNoTeSeND";
			$ln =~ s/\[\d{1,3}\]/$truenote/; 
		}
		push @bodynotes, $ln
	}
# abort if there's something in the footnotes queue
	shift @fnotes && die "The footnotes queue has still lines to process!\n\n" ;
} else {
	#if there's no note, copy the body in the bodynotes array
	@bodynotes = @body
}
$numchapone = 0;
$isbook = 0;
# Another scan and get rid of it.
while (@body) {
	$r = shift @body;
	if ($r =~ m/^\s*<(h2|h3|h4|h5|strong)>\s*(.*)\s*<\/(h2|h3|h4|h5|strong)>\s*$/) {
		# print "$2\n" ; #debug
		if ($2 =~ m/[Cc]hapter 1\b/) {
			$numchapone++ 
		} 
		elsif ($2 =~ m/[Aa]ppendix/) {
			$numappendix++
		}
		elsif ($1 =~ m/h3/) {
			$isbook++ 
		} 
		$has_index++
	}
}

if ( $numchapone >= 1 ) { 
	$preamble_first_line = "\\documentclass[a4paper,12pt,final,oneside]{book}\n\\pagestyle{plain}\n" ;
	$dottedtoc = "\\renewcommand{\\cftchapleader}{\\bfseries\\cftdotfill{\\cftsecdotsep}}"; 
} elsif ($isbook >= 1 ) {
	$preamble_first_line = "\\documentclass[a4paper,12pt,final,oneside]{book}\n\\pagestyle{plain}\n" ;
	$dottedtoc = "\\renewcommand{\\cftchapleader}{\\bfseries\\cftdotfill{\\cftsecdotsep}}" ;
} else {
	$preamble_first_line = "\\documentclass[a4paper,12pt,final]{article}\n" ;
	$dottedtoc = "\\renewcommand{\\cftsecleader}{\\bfseries\\cftdotfill{\\cftdotsep}}" ;
}

$preamble_fonts = <<"EOF";
\\usepackage{fontspec}
\\usepackage{bidi}
\\usepackage{xunicode}
\\usepackage{xltxtra}
\\setmainfont[Mapping=tex-text]{Linux Libertine O}
EOF

    $preamble_hyperref = "\\usepackage[bookmarks=true,unicode=false,colorlinks=false,plainpages=false,pdfpagelabels,xetex]{hyperref}";

$preamble = <<"EOF";
$preamble_fonts 
\\usepackage{polyglossia}
\\setdefaultlanguage[numerals=hebrew]{hebrew}
\\setmainfont{Linux Libertine O}
\\usepackage{url}
\\usepackage{enumerate}
\\usepackage{tocloft}
$dottedtoc
$LATEXCODE
\\usepackage{graphicx}
$preamble_hyperref

%%%%%geometry%%%%%

\\newlength{\\drop}
% author, title, date
\\newcommand{\\titleBeowulf}[3]{\\begingroup% 
\\drop = 0.1\\textheight
\\raggedright
\\parindent=0pt
%\\vspace*{\\drop}
{\\Large {\\bfseries \\itshape #1}\\\\[2\\baselineskip]}
{\\Huge\\bfseries #2 \\\\[\\baselineskip]}
\\vfill
{\\centering \\Large #3\\par
 \\rule{15em}{0.4pt}\\\\[0.5\\baselineskip]}
{\\centering \\Large\\scshape The Anarchist Library\\par}
%\\vspace*{\\drop}

\\endgroup}

EOF

$fix_the_counter = "\\makeatletter\n\\\@addtoreset{chapter}{part}\n\\makeatother\n";

if (! $DATE) {$DATE = ""}

$titling = <<"EOF";
\\author{$AUTHOR}
\\title{$TITLE}
\\date{$DATE}

\\begin{document}
\\setRL
\\raggedright
\\thispagestyle{empty}
\\titleBeowulf{$AUTHOR}{$TITLE}{$DATE}

\\clearpage

EOF

if ($has_index) {
	$table_of_contents="\\tableofcontents\n\\newpage\n" 
}

$impressum =<<EOL;

\\clearpage
\\thispagestyle{empty}
\\begin{center}
\\noindent
\\textsc{\\Large The Anarchist Library} 

\\noindent
\\today\\\\[30pt]
% logo
% \\includegraphics[width=35mm,height=35mm]{logo}
\\end{center}
%\\bigskip
\\vspace{\\stretch{1}}                
\\begin{footnotesize}
\\begin{center}
\\fbox{%
\\begin{minipage}[c]{20em}
\\begin{center}
\\noindent Anti-Copyright.\\\\
http://theanarchistlibrary.org \\\\
EOL

if ($AUTHOR) {$impressum = join("", $impressum, "Author: $AUTHOR \\\\")}
if ($TITLE) {$impressum = join("\n", $impressum, "Title: $TITLE \\\\")}
if ($DATE) {
	$impressum = join("\n", $impressum, "Publication date: $DATE \\\\")
} else {
	$impressum = join("\n", $impressum, "Publication date: Unknown \\\\") 
}
if ($TOPICS) {$impressum = join("\n", $impressum, "Topics: $TOPICS \\\\")}
if ($ADC) {$impressum = join("\n", $impressum, "ADC: $ADC \\\\")}
$impressum = join("\n", $impressum, "\\end{center}\n\\end{minipage}\n\\par } \n\n \\end{center}\n\n\\bigskip\n\\begin{center}");
if ($SOURCE) {$impressum = join("\n", $impressum, "\\noindent $SOURCE\n")}
if ($NOTES) {$impressum = join("\n", $impressum, "\\noindent $NOTES ")}
$impressum = join ("\n", $impressum,"\\end{center}\n\\end{footnotesize}\n\\end{document}\n");


push @dest, $preamble_first_line;
push @dest, $preamble ;
if ($numchapone > 1) { push @dest, $fix_the_counter }
push @dest, $titling ;
if ($table_of_contents) {push @dest, $table_of_contents }

# variable to mark the tags
$end_sep = "EndSectioOrChapter";
$begin_sep = "BeginSectionOrChapter";
$in_verbatim = 0 ;
# the main loop
while (@bodynotes) {
	$clean_line = shift @bodynotes;
	if ( $clean_line =~ m/<pre>/ ) {
		$clean_line =~ s/<pre>/\n\\begin{verbatim}\n/;
		$in_verbatim = 1 ;
	}
	if ( $clean_line =~/<\/pre>/ ) {
		$in_verbatim = 0 ;
	}
	if ( $in_verbatim == 1 ) {
		push @dest, $clean_line;
		next ;
	}
	# here we insert the links verbatim
	$clean_line = &check_urls($clean_line);
	while ( $clean_line =~ m/BeGiNURLHREF([^\s]*?)EndURLHREF/)  {
		$url_token = $1;
		$url_token =~ s/%/\\%/g;
		$url_token =~ s/#/\\#/g;
		$clean_line =~ s/BeGiNURLHREF[^\s]*?EndURLHREF/HERETHERESAFUCKINGURL/;
		# debug 
		# print "$url_token \n";
		push @tmp_array_url, $url_token;
	}
	# print "$clean_line"; #debug
	$clean_line = &clean_the_html($clean_line);
	# print "$clean_line"; #debug
	while ( $clean_line =~ m/HERETHERESAFUCKINGURL/ ) {
		$the_url_token = shift @tmp_array_url || die "Error processing the urls\n\n" ;
		$clean_line =~ s/HERETHERESAFUCKINGURL/\\url{$the_url_token}/;
	}
	shift @tmp_array_url && die "Something wrong with the url processing" ;

	if ($clean_line =~ m/^\s*\\part/) {
		if ($numchapone > 1) { 
			$clean_line =~ s/^\\part.*$/$&\n\\setcounter{chapter}{0}\n\n/ ;
		}
	}

	push @dest, $clean_line;
}

push @dest, $impressum;

open(DEST, "> $outputfile") || die "I cannot open $outputfile, why?\n\n";
while (@dest) {
	$r = shift @dest;
	print DEST "$r"; 
}
close(DEST);












##### SUBROUTINES ################
sub check_urls {
	my $line=shift ;
	$line =~ s/[ \t](www\.[a-zA-Z0-9\-\.]+\.[a-z]+)/ http:\/\/$1/g;
	$line =~ s/^(www\.[a-zA-Z0-9\-\.]+\.[a-z]+)/http:\/\/$1/;
	$line =~ s/((((ht|f)tp(s?))\:\/\/)|(www\.))[a-zA-Z0-9\-\.]+\.([a-z]+)(\:\d+)*(\/[a-zA-Z0-9\:\.\,\;\?\'\\\+&%\$#\=~_\-]+)*/BeGiNURLHREF$&EndURLHREF/g;
	$line =~ s/([\.\;\,])(EndURLHREF)/$2$1/g;
	return $line
}



sub clean_the_html {
	my $line=shift ;
	$line =~ s/^[ \t]*//;
	# strip the <a> tags
	$line =~ s/<a (href|name)[^>]*?>//g;
	$line =~ s/<\/a>//g;
	$line =~ s/<p>/\n/g;
	$line =~ s/<\/p>/\n/g;
	$line =~ s/\\/BACKSLASHBACKSLASH/g;
	$line =~ s/#/\\#/g ;
	$line =~ s/\$/\\\$/g ;
	$line =~ s/%/\\%/g ;
	$line =~ s/&/\\&/g ;
	$line =~ s/_/\\_/g ;
	$line =~ s/{/\\{/g ;
	$line =~ s/}/\\}/g ;
	$line =~ s/~/\\~{}/g ;
	$line =~ s/\^/\\^{}/g ;
	$line =~ s/<ol\s*type\s*=\s*"(a|A|i|I)"\s*>/<ol$1>/g ;
	# $line =~ s/“`/``\\thinspace{}`/g ;
	# $line =~ s/“‘/``\\thinspace{}`/g ;
	# $line =~ s/‘“/`\\thinspace{}``/g ;
	# $line =~ s/`“/`\\thinspace{}``/g ;
	# $line =~ s/'”/'\\thinspace{}''/g ;
	# $line =~ s/’”/'\\thinspace{}''/g ;
	# $line =~ s/”’/''\\thinspace{}'/g ;
	# $line =~ s/”'/''\\thinspace{}'/g ;
	# duble close
	$line =~ s/(’|')("|”)/'\\thinspace ''/g ;
	$line =~ s/("|”)(’|')/''\\thinspace '/g ;
	# duble open
	$line =~ s/("|“)(`|‘)/``\\thinspace `/g ;
	$line =~ s/(`|‘)("|“)/`\\thinspace ``/g ;
	$line =~ s/"\b/``/g ;
	$line =~ s/ "/ ``/g ;
	$line =~ s/^"/``/ ;
	$line =~ s/"/''/g ;
	$line =~ s/ -+ / --- /g ;
	$line =~ s/“/``/g;
	$line =~ s/”/''/g;
	$line =~ s/’/'/g ;
	$line =~ s/‘/`/g;
	$line =~ s/(\. *){2,5}/\\ldots{}/g ;
	$line =~ s/…/\\ldots{}/g;
	$line =~ s/—/---/g;
	$line =~ s/–/---/g;
	$line =~ s/--+/---/g;
	$line =~ s/(\d)--*(\d)/$1--$2/g;
	$line =~ s/----+/---/g;
	$line =~ s/<em>/\\emph{/g ;
	$line =~ s/<\/em>/}/g ;
	$line =~ s/<strong>/\\textbf{/g ;
	$line =~ s/<\/strong>/}/g ;
	$line =~ s/<cite>/\n\\begin{quote}\n/g ;
	$line =~ s/<\/cite>/\n\\end{quote}\n/g ;
	$line =~ s/<blockquote>/\n\\begin{quote}\n/g ;
	$line =~ s/<\/blockquote>/\n\\end{quote}\n/g ;
	$line =~ s/<pre>/\n\\begin{verbatim}\n/g;
	$line =~ s/<\/pre>/\n\\end{verbatim}\n/g;
	$line =~ s/<code>/\n{\\ttfamily /g;
	$line =~ s/<\/code>/}\n/g;
	$line =~ s/<ul>/\n\\begin{itemize}\n/g;
	$line =~ s/<\/ul>/\n\\end{itemize}\n/g;
	$line =~ s/<li>/\n\\item /g;
	$line =~ s/<\/li>/\n/g;
	$line =~ s/<ol>/\n\\begin{enumerate}[1.]\n/g;
	$line =~ s/<ola>/\n\\begin{enumerate}[a.]\n/g;
	$line =~ s/<olA>/\n\\begin{enumerate}[A.]\n/g;
	$line =~ s/<oli>/\n\\begin{enumerate}[i.]\n/g;
	$line =~ s/<olI>/\n\\begin{enumerate}[I.]\n/g;
	$line =~ s/<\/ol>/\n\\end{enumerate}\n/g;
	$line =~ s/<dl>/\n\\begin{description}\n/g;
	$line =~ s/<\/dl>/\n\\end{description}\n/g;
	$line =~ s/<dt>/\n\\item[/g;
	$line =~ s/<\/dt>/]/g;
	$line =~ s/<\/?dd>/\n/g;
	$line =~ s/<br ?\/?> *<br ?\/?>/\\par /g;
	$line =~ s/<br ?\/?>/\\\\ /g;
	$line =~ s/ *FooTNoTeSBeGiN/\\footnote{/g;
	$line =~ s/ *FooTNoTeSeND/}/g ;
	$line =~ s/^\s*<center>\s*(\* *){3}\s*<\/center>\s*$/\\bigskip\n\\begin{center}\n\\textbf{* * *}\n\\end{center}\n\\bigskip\n\n/;
	$line =~ s/^\s*<center>\s*(\* *){4,}\s*<\/center>\s*$/\\newpage\n\n/;
	# part
	$line =~ s/^\s*<h2>\s*[Pp]art\s*[0-9IVXLC]+[\.\:]?\s*(.*?)\s*<\/h2>\s*$/\\part{$1}\n/;
	# high level appendix
	$line =~ s/^\s*<h2>Appendix<\/h2>/\\appendix/; 
	$line =~ s/^\s*<h2>\s*(.*?)\s*<\/h2>\s*$/\\part*{%\n\\phantomsection%\n\\addcontentsline{toc}{part}{\\protect\\numberline{}$1}%\n$1}\n\n/;
	# chapter 
	$line =~ s/^\s*<h3>\s*[Cc]hapter\s*[0-9IVXLC]+[\.\:]?\s*(.*?)\s*<\/h3>\s*$/\\chapter{$1}\n/;
	# appendix
	$line =~ s/^\s*<h3>\s*[Aa]ppendix\s*[0-9A-Z]+[\.\:]?\s*(.*?)\s*<\/h3>\s*$/\\chapter{$1}\n/;
	# chapter without label
	$line =~ s/^\s*<h3>\s*(.*?)\s*<\/h3>\s*$/\\chapter*{%\n\\phantomsection%\n\\addcontentsline{toc}{chapter}{\\protect\\numberline{}$1}%\n$1}\n\n/;
	# section
	$line =~ s/^\s*<h4>\s*[Ss]ection\s*[0-9IVXLC]+[\.\:]?\s*(.*?)\s*<\/h4>\s*$/\\section{$1}\n/;
	# section without label
	$line =~ s/^\s*<h4>\s*(.*?)\s*<\/h4>\s*$/\\section*{%\n\\phantomsection%\n\\addcontentsline{toc}{section}{\\protect\\numberline{}$1}%\n$1}\n\n/;
	# subsection 
	$line =~ s/^\s*<h5>\s*[Ss]ubsection\s*[0-9IVXLC]+[\.\:]?\s*(.*?)\s*<\/h5>\s*$/\\subsection{$1}\n/;
	# subsection without label
	$line =~ s/^\s*<h5>\s*(.*?)\s*<\/h5>\s*$/\\subsection*{%\n\\phantomsection%\n\\addcontentsline{toc}{subsection}{\\protect\\numberline{}$1}%\n$1}\n\n/;
	## appendices
	$line =~ s/BACKSLASHBACKSLASH/\$\\backslash\$/g;


	return $line;
}

