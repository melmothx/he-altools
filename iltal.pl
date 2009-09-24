#!/usr/bin/perl -w
# Public domain. Please report errors, patches, suggestions to 
# marco at angrynerds.com
# Some tests and initial variables
#

$filename = $ARGV[0] || die "Please pass a file.xml as argument\n\n";
-e $filename || die "$filename does not exists\n\n";
-T $filename || die "$filename doesn't look as a text file, exiting\n\n";
$outputfile = $filename ; 
$outputfile =~ s/\.xml/.html/ ;
print "Processing $filename, I'll output on $outputfile\n";

# print "output in $TEXDIRECTORY and $PDFDIRECTORY\n";
## read the file and put it in 3 array: @header, @body, @fnotes
open(IN, "< $filename")  || die "I cannot open $filename, why?\n\n";

# read the file.
$fn_counter = 1; 
$body_fn_counter = 1;
while ($r = <IN>) {
	if ($r =~ m/^\s*<!--.*-->\s*$/) {
		# debug 
		# print $r; 
		push @header, $r;
		# the headers are put in a separate array, we don't need them
	}
	elsif ($r =~ m/^\s*\[\d+\]\s*/) {
		$r =~ s/^\s*(\[\d+\])/<a name="fn$fn_counter"><\/a>$1<a href="#fn_back$fn_counter">^<\/a>/;
		# debug
		# print $r; 
		push @fnotes, $r;
		$fn_counter++;
		# the footnotes at the end go in a separate array, with the <a ready>
	}
	# the rest go in the body
	else {
		while ( $r =~ m/\[\d{1,3}]/ ) {
		$r =~ s/\[\d{1,3}]/Fo_oT_NoTe$body_fn_counter Fo_oT_NoTe/ ;
		$body_fn_counter++  ;
		# debug 
		# print $body_fn_counter ;
		}
		push @orig_body, $r; 
	}
}
close(IN);	

$toc_counter = 1;
while (@orig_body) {
	$r = shift @orig_body ;
	$r =~ s/Fo_oT_NoTe(\d{1,3}) *Fo_oT_NoTe/<a href="#fn$1">[$1]<\/a><a name="fn_back$1"><\/a>/g ;
	$r =~ s/(<h\d>)(.*)(<\/h\d>)/$1<a name="toc$toc_counter">$2<\/a>$3/ ;
	if ($r =~ m/name="toc/) {
		$toc_entry = $r ;
		$toc_entry =~ s/name="/href="#/ ;
		$toc_counter++  ;
		#debug 
		# print $toc_entry;
		push @toc, $toc_entry ;
	}
	push @body, $r 
}

# process the header and extract the fields
# still not used, but will be soon
# @header || die "$no_header_warning\n\n";
# foreach $field_header (@header) {
# 	if ($field_header =~ m/<!--\s*AUTHOR="(.+)"\s*-->/) { 
# 		$AUTHOR=$1;
# 	}
# 	elsif ($field_header =~ m/<!--\s*TITLE="(.+)"\s*-->/) { 
# 		$TITLE=$1;
# 	}
# 	elsif ($field_header =~ m/<!--\s*DATE="(.+)"\s*-->/) { 
# 		$DATE=$1;
# 	}
# 	elsif ($field_header =~ m/<!--\s*TOPICS="(.+)"\s*-->/) { 
# 		$TOPICS=$1;
# 	}
# 	elsif ($field_header =~ m/<!--\s*ADC="(.+)"\s*-->/) { 
# 		$ADC=$1;
# 	}
# 	elsif ($field_header =~ m/<!--\s*SOURCE="(.+)"\s*-->/) { 
# 		$SOURCE=$1;
# 	}
# 	elsif ($field_header =~ m/<!--\s*NOTES="(.+)"\s*-->/) { 
# 		$NOTES=$1;
# 	}
# }
# 
##############################
# temporary
while (@header) {
	$r = shift @header;
	print "$r";
}
###############################

# write the body file
open(DEST, "> $outputfile") || die "I cannot open $outputfile, why?\n\n";
while (@body) {
	$r = shift @body;
	print DEST "$r"; 
}
while (@fnotes) {
	$r = shift @fnotes ;
	print DEST "$r\n";
}
close(DEST);

# try to format the toc 
# The parser has to know which is the parent level, so find the higher
@toc_tmp = @toc ; 
foreach $level (@toc_tmp) {
	$level =~ s/<h(\d)>.*<\/h.>/$1/ ; 
	push @levs, $level;
}

@levs = sort(@levs); 

$oldlevel = $levs[0];
# print "Max level is $oldlevel"; 
## found!
#
$lp_counter = 0;  # probably it's an hack, but we're used to
while (@toc) {
	$r = shift @toc; 
	$current_level = $r ;
	$current_level =~ s/<h(\d)>.*<\/h.>/$1/ ; 
	# replace the <h> with <li>
	$r =~ s/<h\d>/<li>/ ;
	$r =~ s/<\/h\d>/<\/li>/ ;
	# first loop, open!
	while ($lp_counter == 0) {
		push @toc_formatted, "<ul>\n" ;
		$lp_counter++;

	}
	if ($current_level > $oldlevel) {
		push @toc_formatted, "<ul>\n" ;  
		$level_shift = $current_level - $oldlevel;
		while ($level_shift > 1) {
			push @toc_formatted, "<ul>\n";
			$level_shift--;
		}

	} 
	elsif ($current_level < $oldlevel) {
		push @toc_formatted, "</ul>\n";
		$level_shift =  $oldlevel - $current_level;
		while ($level_shift > 1) {
			push @toc_formatted, "</ul>\n";
			$level_shift--;
		}
	}
	# insert the <li>
	push @toc_formatted, $r ; 
	$oldlevel = $current_level; 
}

push @toc_formatted, "</ul>\n\n<br />\n<center> ____________________________________ </center>\n";


# write the toc file
$toc_output = $outputfile ;
$toc_output =~ s/.html/_toc.html/ ;


open(DESTFN, "> $toc_output") || die "I cannot open $outputfile, why?\n\n";
while (@toc_formatted) {
	$r = shift @toc_formatted ;
	print DESTFN "$r";
}
close(DESTFN); 



