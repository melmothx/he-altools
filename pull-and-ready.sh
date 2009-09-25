#!/bin/bash
#################################################
# TODO
#  fix issue that causes auto aliases to shut off
#            META_TITLE="ignore-this-node";
#	CAUTION: remember node numbers!
#################################################
#
# This script prompts the user with a list of unpublished nodes,
# allows the user to select a node from this list, parses this node,
# creates xml file, and asks if it should be reuploaded to form info 
# of drupal.
#
# Usage: pull-and-ready.sh [-p] [-b <nodenumber> ] [-d]
# -p == preserve the single quote even if they look wrong. Could be useful
# -b == batch mode, requires the node number. No interaction
# -d == debug, leave the mess in the temp directory. 
##################################################

#exit on error 
set -e 

if [ "$1" == "-p" ]; then 
	echo "Preserving and not correcting the single quotes"
	PRESERVE="true"
	shift
else 
	PRESERVE="false"
fi

if [ "$1" = "-b" ]; then
	echo "Running in batch mode, no interaction required"
	if [ -z "$2" ]; then 
		echo "You have to provide the node number"
		echo "Example: $0 -b 640"
		echo "Where 640 is http://tal.org/node/640"
		exit 1
	fi
	CLI_ARG="$2"
	echo "Retrieving node number $CLI_ARG"
fi


CWD=$(pwd)
WORKINGDIR=/tmp/$(date -I)-tal
wiki_entry_file=wiki_entry.wiki

# Clean up old unused files
# TMPFILES="clean.tmp drupal-dump.tmp header2.tmp header.tmp menufile.tmp myfile.tmp newfile.tmp OUR_LINE.tmp ready2.tmp ready.tmp node response1.html logo.eps logo.pdf pdf_string.tmp cookie.txt response2.html"
TMPFILES="clean.tmp drupal-dump.tmp header.tmp menufile.tmp myfile.tmp newfile.tmp OUR_LINE.tmp ready.tmp node response1.html logo.eps logo.pdf pdf_string.tmp cookie.txt response2.html"
mkdir -p $WORKINGDIR
cd $WORKINGDIR
rm -f $TMPFILES

# If there is no auth file, create one with username, pass, etc
# else read in this info to variables
if [ ! -e ~/.theanarchistlibrary_auth ]
then
   echo
   echo "Creating ~/.theanarchistlibrary_auth file .."
   echo 
   echo -n "Username?: "
   read name
   echo -n "Password?: "
   stty -echo
   read pass
   stty echo
   echo
   echo "IMPORTANT: Include final / in all websites and pathnames!"
   echo
   echo -n "Website (http://theanarchistlibrary.org/)?: "
   read site
   echo -n "Path to alibrary git (~/mylocalanarchistlibrary/alibrary/)?: "
   read alibrary_path
   echo $name $pass $site $alibrary_path > ~/.theanarchistlibrary_auth
   chmod 600 ~/.theanarchistlibrary_auth
else
   read name pass site alibrary_path < ~/.theanarchistlibrary_auth
fi


interactive_menu () {

admin_site=${site}admin/content/node

# get cookie / login / download page
# wget various time on purpose. Don't fucking touch
cookie=`wget -S -O /dev/null $admin_site 2>&1 | awk '/Set-Cookie/{print $4}' FS='[ ;]'`
cookie=`wget -S -O /dev/null --header="Cookie: $cookie" --post-data="name=$name&pass=$pass&op=Log%20in&form_id=user_login_block" "${admin_site}?q=node&destination=node" 2>&1 | awk '/Set-Cookie/{print $4}' FS='[ ;]' | awk 'NR==2{print}'`
wget --header="Cookie: $cookie" $admin_site

# menu unfixed
MENU_TITLE_UNFX=$(grep '<td>not published</td>' node  | sed -e 's/^.*<a\ href="\(.*\)"<\/a>\ /\1/')
MENU_TITLE=`echo $MENU_TITLE_UNFX | sed -e "s/<\/td> <\/tr> <\/td>/\n\r/g" | sed -e G`
echo $MENU_TITLE > myfile.tmp

cat myfile.tmp | sed -e 's/<td>//g' -e 's/<\/td>//g' -e 's/<\/tr>//g' |\
sed -e 's/\">edit<\/a>//g' -e 's/<\/a>not\ publishedLanguage\ neutral<a href=\"/\ /g' |\
sed -e 's/<\/a>\ Library\ Entries<a\ href=\"/\ /g' -e 's/<a href=\"/\ /g' |\
sed -e 's/<span\ class=\"marker\">new<\/span>Library\ Entries\ //g' |\
sed -e 's/"\ title=\"View user profile\.\">//g' -e 's/<\/a>//g' |\
sed -e 's/\">/\ /g' -e 's/?destination=admin%2Fcontent%2Fnode//g' |\
tr '\r' '\n' > newfile.tmp

cat newfile.tmp | sed -e 's/\/user.*//' |\
sed -e 's/\ [^ ]* //' > menufile.tmp

sed = menufile.tmp | sed 'N;s/\n/\t/' 

echo -n "Which node would you like to prepare? (number): "
read NUMBER

## strip the file of everything but that line number
cat newfile.tmp | sed "${NUMBER}q;d" > OUR_LINE.tmp

## end block for interactive menu
}

if [ ! -z "$CLI_ARG" ]; then
	NODE_NUMBER=node/$CLI_ARG/edit 
else
	# if no command line args, we run the menu 
	interactive_menu 
	NODE_NUMBER=`cat OUR_LINE.tmp | sed -ne 's/.*\(node.*edit\).*/\1/p'`
fi

node_site=http://www.theanarchistlibrary.org/$NODE_NUMBER

#THE PULL SCRIPT
cookie=`wget -S -O /dev/null $node_site 2>&1 | awk '/Set-Cookie/{print $4}' FS='[ ;]'`
cookie=`wget -S -O /dev/null --header="Cookie: $cookie" --post-data="name=$name&pass=$pass&op=Log%20in&form_id=user_login_block" "${node_site}?q=node&destination=node" 2>&1 | awk '/Set-Cookie/{print $4}' FS='[ ;]' | awk 'NR==2{print}'`
wget --header="Cookie: $cookie" $node_site
mv edit drupal-dump.tmp

cat drupal-dump.tmp | sed -e "1,/\ <label\ for=\"edit-body/d" |\
sed -e '/<fieldset\ class=\"\ collapsible\ collapsed\"><legend>Input\ format<\/legend><div class=\"form-item"\ id=\"edit-format-1-wrapper\">/,$d' |\
sed -e '/<div>/d' -e '/<\/div>/d' -e 's/<\/textarea>//g'|\
#-e '/<\/textarea>/d' |\
sed -e 's/^ $//' |\
sed -e "s/\ <textarea\ cols=\"60\"\ rows=\"20\"\ name=\"body\"\ id=\"edit-body\"\ \ class=\"form-textarea\ resizable\">//" |\
sed -e "s/&lt;/</g" \
  -e "s/&gt;/>/g" \
  -e "s/&\#039;/\'/g" \
  -e "s/&amp;/\&/g" \
  -e "s/&quot;/\"/g" > clean.tmp

clean_field () {
	echo $@ | \
	sed -e "s/&lt;/</g" \
	-e "s/&gt;/>/g" \
	-e "s/&\#039;/\'/g" \
	-e "s/&amp;/\&/g" \
	-e "s/&quot;/\"/g" 
}

# extract META info from drupal-dump.tmp
AUTHOR=$(clean_field $(grep 'id="edit-field-author-0-value"' drupal-dump.tmp  | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/' -e 's/ *$//'))
TITLE=$(clean_field $(grep 'id="edit-title"' drupal-dump.tmp  | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/' -e 's/ *$//')) 
DATE=$(clean_field $(grep 'id="edit-field-pubdate-0-value"' drupal-dump.tmp  | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/'))
SOURCE=$(clean_field $(grep 'id="edit-field-source-0-value"' drupal-dump.tmp | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/'))
TOPICS=$(clean_field $(grep 'id="edit-taxonomy-tags-1"' drupal-dump.tmp | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/')) 
ADC=$(clean_field $(grep 'id="edit-field-adc-0-value"' drupal-dump.tmp | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/' ))
NOTES=$(clean_field $(grep 'id="edit-field-notes-0-value"' drupal-dump.tmp | sed -e 's/^.*class="form-textarea resizable">\(.*\)\(<\/textarea>.*\)\?/\1/' -e 's/\r//g' -e 's|</textarea>||')) 
UPLOADER=$(clean_field $(grep 'name="name" id="edit-name"' drupal-dump.tmp | sed -e 's/^.*value="\(.*\)" class="form-text.*$/\1/'))



# PREPARE FOR THE UPLOAD
echo "The following lines are supposed to be messed up"
( cat clean.tmp | fmt | grep -e '\>- ' )
( cat clean.tmp | fmt | grep -e " \" " )
( cat clean.tmp | fmt | grep -e '\>-[^A-Za-z]' )
( cat clean.tmp | fmt | grep -e ' -\< ' )

# build the header but don't put the topic field inside
cat <<EOF > header.tmp
<!-- AUTHOR="$AUTHOR" -->
<!-- TITLE="$TITLE" -->
<!-- DATE="$DATE" -->
<!-- TOPICS="" -->
<!-- ADC="$ADC" -->
<!-- SOURCE="$SOURCE" -->
<!-- NOTES="$NOTES" --> 

EOF


# first strip the header and the <a> 

sed -e '/^<!--.*-->/d' \
    -e "s/\r$//" \
    -e 's/<a href="#fn_back[0-9]*">^<\/a>//' \
    -e 's/<a [^>]*>//g' \
    -e 's|</a>||g' \
    -e 's/"\</“/g' \
    -e 's/^"/“/' \
    -e 's/ "/ “/g' \
    -e 's/"/”/g' \
    -e 's/``/“/g' \
    -e "s/''/”/g" \
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
    -e "s|^[\t ]*<strong>[\t ]*\(Part.*\)</strong>[\t ]*$|<h2>\1</h2>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Chapter.*\)</strong>[\t ]*$|<h3>\1</h3>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Section.*\)</strong>[\t ]*$|<h4>\1</h4>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Subsection.*\)</strong>[\t ]*$|<h5>\1</h5>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Appendix\)[\t ]*</strong>[\t ]*$|<h2>\1</h2>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(Appendix .*\)</strong>[\t ]*$|<h3>\1</h3>|" \
    -e "s|^[\t ]*<strong>[\t ]*\(.*\)</strong>[\t ]*$|<h4>\1</h4>|" \
    -e 's|</*p>|\n\n|g' clean.tmp >> ready.tmp

# fix problem with header
# cat header.tmp | sed -e "s/\&quot\;/\"/g" | sed -e "s/\&#039\;/\'/g" > header2.tmp
# cat ready.tmp | sed -e "s/\r$//"  > ready2.tmp

# fix a bad sostitution of the <ol>

sed -i 's|<ol *type *= *[“”]\(.\)[“”] *>|<ol type="\1">|g' ready.tmp 

if [ "$PRESERVE" != "true" ]; then 
	sed -i "s/ '\([A-Za-z]\)/ \`\1/g" ready.tmp 
        sed -i  "s/^'\([A-Za-z]\)/\`\1/g" ready.tmp 
    	sed -i 's/ *— */ — /g' ready.tmp 
else
	echo "Preserving the single quotes"
fi

# merge meta info and create file according to convention
# change spaces in filename with underscores

## I'll start with the accent translation. BE SURE YOU HAVE A UTF-8 LOCALE (type: "locale" on the
# shell. 
filenamefixed=$(echo ${AUTHOR}__${TITLE}.xml | sed -e "s/[^a-zA-Z0-9_.-]/_/g" | sed -e "y/àáÈÉëèéìíòóùúç/aaEEeeeiioouuc/")

# it looks like the & are not replaced
# cat header2.tmp ready2.tmp | sed -e 's/&amp;/\&/g' > $filenamefixed
cat header.tmp ready.tmp | cat -s  > $filenamefixed 

# now we have the file! (cat -s remove the multiple blank lines)

( cp ${alibrary_path}logo.{eps,pdf} $WORKINGDIR ) 
if [ -f "logo.eps" ] && [ -f "logo.pdf" ]
then 
	he-d2l.sh  $filenamefixed
  PDF_LINK=`cat pdf_string.tmp`
else
  echo "Skipping pdf build: your alibrary path seems broken"
fi

# now we process it with the other perl parser to create the linking and the toc
iltal.pl $filenamefixed > /dev/null
# this will produced 2 files: 

html_body=$(basename $filenamefixed .xml).html
html_toc=$(basename $filenamefixed .xml)_toc.html
n_lines_toc=$(wc -l $html_toc | cut -f1 -d " ") 
if [ $n_lines_toc == 4 ] ; then
	: > $html_toc
fi

## here we squeeze the blank lines in the body, because the il2tal.pl leaves a pack of blank consecutive lines

cat -s $html_body  > veryverytmphtmlbody
mv veryverytmphtmlbody  $html_body 

upload_the_stuff () {
	# login
	login_site="${site}/?q=user"
	curl $login_site \
        	-s \
        	-c cookie.txt \
        	-b cookie.txt \
        	-F "name=${name}" \
        	-F "pass=${pass}" \
        	-F 'form_id=user_login' \
        	-F 'op=Log in' \
        	--output response0.html

	# get form
	curl ${site}${NODE_NUMBER} \
	-s -c cookie.txt -b cookie.txt --output response1.html
	
	TOKEN=$(grep 'edit-library-node-form-form-token' response1.html |\
	sed -e 's/^.*value="\(.*\)"  \/.*$/\1/')

	# reupload form
#	AUTHOR_TR=`echo ${AUTHOR} | tr ' ' '_'`
#	TITLE_TR=`echo ${TITLE} | tr ' ' '_'`
#	BODY=`cat ${AUTHOR_TR}__${TITLE_TR}.xml`
#commented out because it's used as $filenamefixed. It avoids special characters in filenames
# make it lesser than 120 chars
auto_alias=$(echo $filenamefixed | sed -e "s/_/-/g" -e "s/--\+/-/g" -e "s/\.xml//" -e "s/\(.\{,120\}\).*/\1/" | tr "A-Z" "a-z") 

# dump notes and source to a tmp file and read from there
echo $SOURCE > ${filenamefixed}.thesource.tmp
echo $NOTES > ${filenamefixed}.thenotes.tmp

   	curl ${site}${NODE_NUMBER} \
		-S \
        	-c cookie.txt \
        	-b cookie.txt  \
	        -F "title=${TITLE}" \
		-F "field_toc[0][value]=<$html_toc" \
		-F "body=<$html_body" \
	        -F "field_author[0][value]=${AUTHOR}" \
		-F "field_pubdate[0][value]=${DATE}" \
		-F "field_adc[0][value]=${ADC}" \
		-F "taxonomy[tags][1]=${TOPICS}" \
		-F "field_source[0][value]=<${filenamefixed}.thesource.tmp" \
		-F "field_notes[0][value]=<${filenamefixed}.thenotes.tmp" \
		-F 'print_display=checked' \
		-F 'print_display_urllist=checked' \
		-F "name=${UPLOADER}" \
		-F "field_pdf[0][value]=${PDF_LINK}" \
		-F "pathauto_perform_alias=0" \
		-F "path=$auto_alias" \
		-F 'op=Save' \
		-F 'form_id=library_node_form' \
		-F "form_token=${TOKEN}" \
		--output response2.html

rm ${filenamefixed}.thenotes.tmp ${filenamefixed}.thesource.tmp
	## here the function ends 
	}

up_and_checkin () {
	upload_the_stuff 
	echo "Moving $filenamefixed to the git" 
	mv $filenamefixed $alibrary_path 
}

if [ -z $CLI_ARG ]; then 
	echo
	echo -n "Would you like to upload $filenamefixed to drupal? (y/n) >>> "
	read yorn
	if [ $yorn == 'y' ]; then
		up_and_checkin 
	fi
else 
	up_and_checkin 
fi

echo "Author: $AUTHOR"
echo "Title: $TITLE"
echo "Date: $DATE"
echo "Source: $SOURCE"
echo "Notes: $NOTES"
echo "Uploader: $UPLOADER"
echo

if [ -z "$AUTHOR" ]; then
	echo "Missing AUTHOR  field!"
fi
if [ -z "$TITLE" ]; then
	echo "Missing TITLE  field!"
fi
if [ -z "$DATE" ]; then
	echo "Missing DATE  field!"
fi
if [ -z "$SOURCE" ]; then
	echo "Missing source  field!"
fi
if [ -z "$NOTES" ]; then
	echo "Missing notes  field!"
fi
if [ -z "$UPLOADER" ]; then
	echo "Missing UPLOADER  field!"
fi
if [ -z "$TOPICS" ]; then
	echo "Missing TOPIC  field!"
fi
if [ -z "$ADC" ]; then
	echo "Missing ADC  field!"
fi
if [ -z "$PDF_LINK" ]; then
	echo "Missing PDF  field!"
fi
if [ -z "$TOKEN" ]; then
	echo "Missing  TOKEN field!"
fi

cp drupal-dump.tmp $CWD/$filenamefixed.orig.html
# clean up / make safer / user variables
if [ "$3" = "-d" ]; then 
       exit 0
fi       
rm -f $TMPFILES
rm -f $html_body $html_toc

# it could be already in the git 
if [ -f $filenamefixed ] ; then 
	mv $filenamefixed $CWD 
fi

rm -rf $WORKINGDIR/pdf_archive
rm -rf $WORKINGDIR/LaTeX_archive


cd $CWD 
( rmdir $WORKINGDIR 2> /dev/null )
echo "Wiki entry in $wiki_entry_file"
echo 

dest_url=$(echo ${site}${NODE_NUMBER} | sed -e "s|/edit$||")
author_reformatted=$(echo $AUTHOR | sed -e 's|^ *\([^ ]\+\) \+\(.*\)$|\2, \1|')
cat << EOF >> $wiki_entry_file
|-
! $author_reformatted
| $TITLE || $dest_url || $UPLOADER || ||

EOF

exit 0 

