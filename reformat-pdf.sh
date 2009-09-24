#!/bin/bash
set -e

SERVER="http://theanarchistlibrary.org"
TEXDIR="sites/default/files/src"
PAPER_DEFAULT="a4"
DEFAULT_FORMAT_OPTIONS="top=0.5in,bottom=0.6in"
signatures=""

if [ -z "$1" ] ; then 
	echo "Usage $0 pdf_name [a4|letter] [format options...]"
	echo "Example: $0 Voltairine_de_Cleyre__Direct_Action_a4.pdf letter \\"
	echo "\"$DEFAULT_FORMAT_OPTIONS\""
	exit 1 
fi

TEXNAME=$(echo $1 | sed -e "s/pdf$/tex/")

if [ "$2" != "letter" -a "$2" != "a4" ] ; then 
	echo "No paper format specified. Defaulting to $PAPER_DEFAULT"
	paper=$PAPER_DEFAULT
	shift
else
	paper=$2
	shift
fi

if [ "$2" == "-s" ]; then
	signatures="-s$3"
	shift ; shift
fi

if  echo $2 | grep -q -e "top\|bottom\|outer\|inner" ; then  
	format_options="$2"
else
	format_options="$DEFAULT_FORMAT_OPTIONS"
fi


clear
# fetch the .tex source, skip if already present 
if [ ! -f $TEXNAME ]; then 
	echo -e "\033[1mwget $SERVER/$TEXDIR/$TEXNAME\033[0m" 
	wget $SERVER/$TEXDIR/$TEXNAME 
fi

orig_format=$(echo $TEXNAME | sed -e "s%.*\(a4\|letter\)\(_imposed\)\?\.tex$%\1\2%")
echo "The original format was $orig_format"

DESTFILE=$(echo $TEXNAME | sed -e "s/${orig_format}/__${paper}_custom/")
cp $TEXNAME $DESTFILE
echo
echo "output in $DESTFILE"
echo
echo "Editing $DESTFILE..., making it twoside, inserting your geometry and unbranding"
if [ "$orig_format" == "a4" ] || [ "$orig_format" == "letter" ] ; then 
	# make it twoside
	sed -i "1s/\(\\documentclass\)\(.*\)\(letter\|a4\)paper\(.*\)/\1\2a5paper,twoside\4/" $DESTFILE
	# set the geometry
	sed -i "1,30s/^%%%%%geometry%%%%/\\\usepackage[a5paper,includeheadfoot,${format_options}]{geometry}/" $DESTFILE
else
	# make it twoside
	sed -i "1s/\\documentclass[a5paper,/&twoside,/"
	# set geometry on a5, where it's already set
	sed -i "1,30s/^\(\\\usepackage\).*\({geometry}\)/\1[a5paper,includeheadfoot,${format_options}]\2/" $DESTFILE
fi

# remove the logo (unbranding ;-) 
sed -i "/includegraphics.*{logo}/d" $DESTFILE 


# compile
echo -ne "Compiling the .tex source... (\033[1mpdflatex $DESTFILE\033[0m) "
pdflatex -halt-on-error $DESTFILE >/dev/null  
if [ "$?" != "0" ]; then 
	tail -n 30 $(basename $DESTFILE .tex).log
	echo "Compilation errors... this should not happen" 
	exit 2
fi
pdflatex -halt-on-error $DESTFILE >/dev/null  
echo -n "done"
echo 
TEXBASENAME=$(basename $DESTFILE .tex) 

echo 
echo -ne "Imposing... ( \"\033[1mpdftops -level3sep  $TEXBASENAME.pdf - | psbook $signatures -q | psnup -q -2 -Pa5 -p${paper}  > ${TEXBASENAME}.ps\033[0m \" ) " 
pdftops -level3sep  $TEXBASENAME.pdf - | \
	psbook $signatures -q | \
	psnup -q -2 -Pa5 -p${paper}  > ${TEXBASENAME}.ps
echo "done"
echo

# create a high-quality pdf

echo -ne "Creating a high quality pdf... ( \033[1mps2pdf -dPDFSETTINGS=/printer -dUseCIEColor=true -dPDFA -sPAPERSIZE=${paper} ${TEXBASENAME}.ps\033[0m ) "
ps2pdf -dPDFSETTINGS=/printer \
	-dUseCIEColor=true \
	-dPDFA \
	-sPAPERSIZE=${paper} ${TEXBASENAME}.ps
echo
# clean the mess
echo -e "cleaning... \033[1mrm -f ${TEXBASENAME}{.out,.aux,.dvi,.log,.ps,.toc}\033[0m" 
rm -f ${TEXBASENAME}{.aux,.dvi,.log,.ps,.toc}
echo
echo "Your new file is ${TEXBASENAME}.pdf . Enjoy! I'll leave $DESTFILE here for your pleasure"
tput sgr0
