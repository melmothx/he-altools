#!/bin/bash 
## hey, emacs, -*- mode: sh; -*-

set -e

if [ ! -f $1 ]; then
    echo "the argument is not a file, exiting"
    echo "did you ready the TUTORIAL.txt?"
    exit 1
fi

echo "The following lines are supposed to be messed up"
( cat $1 | fmt | grep -e '\>- ' )
( cat $1 | fmt | grep -e " \" " )
( cat $1 | fmt | grep -e '\>-[^A-Za-z]' )
( cat $1 | fmt | grep -e ' -\< ' )

echo 
echo

echo "Please answer the following questions, just hit enter if empty "
echo -n "author? >> " 
read AUTHOR
echo -n "title? >> " 
read TITLE
echo -n "Date of original publication of article or text? >> " 
read DATE
echo -n "Topics? >> " 
read TOPICS
echo -n "ADC? >> " 
read ADC
echo -n "Do you want to add some notes? Write them *now* >> " 
read NOTES
echo -n "Where does this entry originate? URL or hit enter >> "
read SOURCE_URL
SOURCE="Retrieved on $(LC_ALL="en_US.UTF-8" date +%B" "%e," "%Y) from $SOURCE_URL"
if [ "$SOURCE_URL" == "" ]; then
	echo -n "Where does this entry originate? Use APA format if possible. >> " 
	read SOURCE
fi

cat <<EOF > $1.new
<!-- AUTHOR="$AUTHOR" -->
<!-- TITLE="$TITLE" -->
<!-- DATE="$DATE" -->
<!-- TOPICS="$TOPICS" -->
<!-- ADC="$ADC" -->
<!-- SOURCE="$SOURCE" -->
<!-- NOTES="$NOTES" --> 

EOF

sed -e 's/"\</“/g' \
    -e 's/^"/“/' \
    -e 's/ "/ “/g' \
    -e 's/"/”/g' \
    -e 's/``/“/g' \
    -e "s/''/”/g" \
    -e "s/ '\([A-Za-z]\)/ \`\1/g" \
    -e "s/^'\([A-Za-z]\)/\`\1/g" \
    -e "s/­/-/g" \
    -e "s/‑/-/g" \
    -e "s/–/—/g" \
    -e "s/ﬁ/fi/g" \
    -e "s/ﬂ/fl/g" \
    -e "s/ﬃ/ffi/g" \
    -e "s/ﬄ/ffl/g" \
    -e "s/ﬀ/ff/g" \
    -e 's/ \+- \+/ -- /g' \
    -e 's/--\+/—/g' \
    -e 's/…/.../g' \
    -e 's/ *— */ — /g' \
    -e 's|@@@strong@@@|<strong>|g' \
    -e 's|@@@endstrong@@@|</strong>|g' \
    -e 's|@@@blockquote@@@|<blockquote>|g' \
    -e 's|@@@endblockquote@@@|</blockquote>|g' \
    -e 's|@@@italics@@@|<em>|g' \
    -e 's|@@@enditalics@@@|</em>|g' \
    -e 's|@@@header\([0-9]\)@@@|<h\1>|g' \
    -e 's|@@@endheader\([0-9]\)@@@|</h\1>|g' \
    -e "s|^[\t ]*<strong>[\t ]*\(Part.*\)</strong>[\t ]*$|<h2>\1</h2>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Chapter.*\)</strong>[\t ]*$|<h3>\1</h3>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Section.*\)</strong>[\t ]*$|<h4>\1</h4>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Subsection.*\)</strong>[\t ]*$|<h5>\1</h5>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Appendix\)[\t ]*</strong>[\t ]*$|<h2>\1</h2>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Appendix .*\)</strong>[\t ]*$|<h3>\1</h3>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(.*\)</strong>[\t ]*$|<h4>\1</h4>|" \
    -e 's|</*p>|\n\n|g' $1 >> $1.new

if [ "$?" != "0" ]; then
    echo Error!
    exit 2
fi

mv $1 $1.old
mv $1.new $1

exit 0

    


